import 'package:flutter/foundation.dart';
import 'package:finance_tracker/models/budget.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/services/database_service.dart';

class BudgetProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets() async {
    // Don't notify at the start of loading
    _isLoading = true;

    _budgets = await _databaseService.getBudgets();

    _isLoading = false;
    notifyListeners(); // Only notify once at the end
  }

  Future<void> addBudget(Budget budget) async {
    await _databaseService.insertBudget(budget);
    await loadBudgets();
  }

  Future<void> updateBudget(Budget budget) async {
    await _databaseService.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _databaseService.deleteBudget(id);
    await loadBudgets();
  }

  Map<String, double> calculateBudgetProgress(List<Transaction> transactions) {
    final Map<String, double> progress = {};

    for (final budget in _budgets) {
      double spent = 0;

      // Filter transactions by date range and category
      final filteredTransactions = transactions.where((transaction) {
        // Check if the transaction is an expense
        final isExpense = transaction.type == TransactionType.expense;

        // Check if the transaction is within the budget's date range
        final isWithinDateRange = transaction.date.isAfter(budget.startDate) &&
            (budget.endDate == null ||
                transaction.date.isBefore(budget.endDate!));

        // Check if the transaction belongs to the budget's category
        final matchesCategory = budget.categoryId == null ||
            transaction.categoryId == budget.categoryId;

        return isExpense && isWithinDateRange && matchesCategory;
      });

      // Calculate total amount spent
      for (final transaction in filteredTransactions) {
        spent += transaction.amount;
      }

      // Calculate progress as a percentage
      progress[budget.id] = (spent / budget.amount).clamp(0.0, 1.0);
    }

    return progress;
  }

  Map<String, double> calculateAmountSpent(List<Transaction> transactions) {
    final Map<String, double> spent = {};

    for (final budget in _budgets) {
      double total = 0;

      // Filter transactions by date range and category
      final filteredTransactions = transactions.where((transaction) {
        final isExpense = transaction.type == TransactionType.expense;
        final isWithinDateRange = transaction.date.isAfter(budget.startDate) &&
            (budget.endDate == null ||
                transaction.date.isBefore(budget.endDate!));
        final matchesCategory = budget.categoryId == null ||
            transaction.categoryId == budget.categoryId;

        return isExpense && isWithinDateRange && matchesCategory;
      });

      // Calculate total amount spent
      for (final transaction in filteredTransactions) {
        total += transaction.amount;
      }

      spent[budget.id] = total;
    }

    return spent;
  }
}
