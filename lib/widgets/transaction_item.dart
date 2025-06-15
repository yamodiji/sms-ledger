import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side - Bank Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Center(
                child: Text(
                  transaction.bankLogo,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Middle - Bank Name, Transaction Type, Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.bank,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTransactionTypeColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getTransactionTypeColor().withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          transaction.transactionTypeDisplay,
                          style: TextStyle(
                            color: _getTransactionTypeColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormatter.format(transaction.date)} • ${timeFormatter.format(transaction.date)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: transaction.isCredit ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                  color: transaction.isCredit ? Colors.green[600] : Colors.red[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionTypeColor() {
    switch (transaction.transactionType) {
      case 'DEBIT_CARD':
        return Colors.blue;
      case 'CREDIT_CARD':
        return Colors.purple;
      case 'UPI':
        return Colors.orange;
      case 'OTHER':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
} 