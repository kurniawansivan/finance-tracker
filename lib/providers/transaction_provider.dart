// ignore_for_file: unnecessary_cast

import 'package:flutter/foundation.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/services/database_service.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions() async {
    // Don't notify at the start of loading
    _isLoading = true;

    if (_startDate != null && _endDate != null) {
      final dynamicList = await _databaseService.getTransactionsByDateRange(
          _startDate!, _endDate!);
      _transactions = dynamicList.map((item) => item as Transaction).toList();
    } else {
      final dynamicList = await _databaseService.getTransactions();
      _transactions = dynamicList.map((item) => item as Transaction).toList();
    }

    _isLoading = false;
    notifyListeners(); // Only notify once at the end
  }

  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _databaseService.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _databaseService.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _databaseService.deleteTransaction(id);
    await loadTransactions();
  }

  double getTotalIncome() {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double getTotalExpenses() {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double getTotalSavings() {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.savings)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  List<Transaction> getTransactionsByCategory(String categoryId) {
    return _transactions
        .where((transaction) => transaction.categoryId == categoryId)
        .toList();
  }

  double getTotalByCategory(String categoryId) {
    return _transactions
        .where((transaction) =>
            transaction.categoryId == categoryId &&
            transaction.type == TransactionType.expense)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  Map<DateTime, double> getExpensesByDate() {
    final Map<DateTime, double> result = {};

    for (final transaction
        in _transactions.where((t) => t.type == TransactionType.expense)) {
      final date = DateTime(
          transaction.date.year, transaction.date.month, transaction.date.day);
      result[date] = (result[date] ?? 0) + transaction.amount;
    }

    return result;
  }

  Map<String, double> getExpensesByCategory() {
    final Map<String, double> result = {};

    for (final transaction
        in _transactions.where((t) => t.type == TransactionType.expense)) {
      result[transaction.categoryId] =
          (result[transaction.categoryId] ?? 0) + transaction.amount;
    }

    return result;
  }
}
