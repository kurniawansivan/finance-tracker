import 'package:finance_tracker/models/transaction.dart';

class MonthlySummary {
  final DateTime month; // Year and month (day will be 1)
  final double totalIncome;
  final double totalExpenses;
  final double totalSavings;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByCategory;

  MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.expensesByCategory,
    required this.incomeByCategory,
  });

  double get balance => totalIncome - totalExpenses;
  double get savingsRate =>
      totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0;
  double get expenseRate =>
      totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0;

  static MonthlySummary fromTransactions(
      List<Transaction> transactions, DateTime month) {
    // Filter transactions for the specified month
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    final monthlyTransactions = transactions
        .where((t) =>
            t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            t.date.isBefore(monthEnd.add(const Duration(days: 1))))
        .toList();

    // Calculate totals
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalSavings = 0;
    Map<String, double> expensesByCategory = {};
    Map<String, double> incomeByCategory = {};

    for (final transaction in monthlyTransactions) {
      switch (transaction.type) {
        case TransactionType.income:
          totalIncome += transaction.amount;
          incomeByCategory[transaction.categoryId] =
              (incomeByCategory[transaction.categoryId] ?? 0) +
                  transaction.amount;
          break;
        case TransactionType.expense:
          totalExpenses += transaction.amount;
          expensesByCategory[transaction.categoryId] =
              (expensesByCategory[transaction.categoryId] ?? 0) +
                  transaction.amount;
          break;
        case TransactionType.savings:
          totalSavings += transaction.amount;
          break;
        case TransactionType.transfer:
          // Transfers don't affect the monthly summary directly
          break;
      }
    }

    return MonthlySummary(
      month: monthStart,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
      expensesByCategory: expensesByCategory,
      incomeByCategory: incomeByCategory,
    );
  }
}
