import 'package:flutter/foundation.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:finance_tracker/models/monthly_summary.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/models/category.dart';

class MonthlyAnalysisProvider with flutter.ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<MonthlySummary> _monthlySummaries = [];
  List<Transaction> _allTransactions = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  bool get isLoading => _isLoading;
  DateTime get currentMonth => _currentMonth;
  MonthlySummary? get currentMonthlySummary {
    if (_monthlySummaries.isEmpty) return null;
    final current = _monthlySummaries.firstWhere(
      (summary) =>
          summary.month.year == _currentMonth.year &&
          summary.month.month == _currentMonth.month,
      orElse: () => MonthlySummary(
        month: _currentMonth,
        totalIncome: 0,
        totalExpenses: 0,
        totalSavings: 0,
        expensesByCategory: {},
        incomeByCategory: {},
      ),
    );
    return current;
  }

  Future<void> loadData() async {
    // Don't notify at the start of loading
    _isLoading = true;

    // Load all transactions (we'll filter by month in the UI)
    final transactions = await _databaseService.getTransactions();
    _allTransactions = transactions;

    // Load all categories for display
    _categories = await _databaseService.getCategories();

    // Generate monthly summaries for the past 12 months
    _generateMonthlySummaries();

    _isLoading = false;
    notifyListeners(); // Only notify once at the end
  }

  void _generateMonthlySummaries() {
    final now = DateTime.now();
    _monthlySummaries = [];

    // Generate summaries for the past 12 months
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final summary = MonthlySummary.fromTransactions(_allTransactions, month);
      _monthlySummaries.add(summary);
    }

    // Sort from newest to oldest
    _monthlySummaries.sort((a, b) => b.month.compareTo(a.month));
  }

  void setCurrentMonth(DateTime month) {
    _currentMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }

  String getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        name: 'Unknown',
        icon: Icons.category,
        color: Colors.grey,
      ),
    );
    return category.name;
  }

  // Get category by ID
  Category? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(
          name: 'Unknown',
          icon: Icons.category,
          color: Colors.grey,
        ),
      );
    } catch (e) {
      return Category(
        name: 'Unknown',
        icon: Icons.category,
        color: Colors.grey,
      );
    }
  }

  Map<String, double> getCategoryPercentages(
      Map<String, double> categoryAmounts) {
    final total =
        categoryAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    if (total <= 0) return {};

    final Map<String, double> percentages = {};
    categoryAmounts.forEach((categoryId, amount) {
      percentages[categoryId] = (amount / total) * 100;
    });

    return percentages;
  }

  List<MapEntry<String, double>> getSortedCategoryExpenses() {
    if (currentMonthlySummary == null) return [];

    final entries = currentMonthlySummary!.expensesByCategory.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<MapEntry<String, double>> getSortedCategoryIncome() {
    if (currentMonthlySummary == null) return [];

    final entries = currentMonthlySummary!.incomeByCategory.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // Compare with previous month
  double getIncomeGrowth() {
    if (_monthlySummaries.length < 2) return 0;
    if (currentMonthlySummary == null) return 0;

    // Find previous month summary
    final currentIndex = _monthlySummaries.indexWhere((summary) =>
        summary.month.year == _currentMonth.year &&
        summary.month.month == _currentMonth.month);

    if (currentIndex < 0 || currentIndex >= _monthlySummaries.length - 1) {
      return 0;
    }

    final previousSummary = _monthlySummaries[currentIndex + 1];
    if (previousSummary.totalIncome == 0) return 0;

    return ((currentMonthlySummary!.totalIncome - previousSummary.totalIncome) /
            previousSummary.totalIncome) *
        100;
  }

  double getExpenseGrowth() {
    if (_monthlySummaries.length < 2) return 0;
    if (currentMonthlySummary == null) return 0;

    // Find previous month summary
    final currentIndex = _monthlySummaries.indexWhere((summary) =>
        summary.month.year == _currentMonth.year &&
        summary.month.month == _currentMonth.month);

    if (currentIndex < 0 || currentIndex >= _monthlySummaries.length - 1) {
      return 0;
    }

    final previousSummary = _monthlySummaries[currentIndex + 1];
    if (previousSummary.totalExpenses == 0) return 0;

    return ((currentMonthlySummary!.totalExpenses -
                previousSummary.totalExpenses) /
            previousSummary.totalExpenses) *
        100;
  }

  double getSavingsGrowth() {
    if (_monthlySummaries.length < 2) return 0;
    if (currentMonthlySummary == null) return 0;

    // Find previous month summary
    final currentIndex = _monthlySummaries.indexWhere((summary) =>
        summary.month.year == _currentMonth.year &&
        summary.month.month == _currentMonth.month);

    if (currentIndex < 0 || currentIndex >= _monthlySummaries.length - 1) {
      return 0;
    }

    final previousSummary = _monthlySummaries[currentIndex + 1];
    if (previousSummary.totalSavings == 0) return 0;

    return ((currentMonthlySummary!.totalSavings -
                previousSummary.totalSavings) /
            previousSummary.totalSavings) *
        100;
  }
}
