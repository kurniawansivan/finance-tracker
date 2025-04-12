import 'package:flutter/foundation.dart' hide Category;
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  List<Category> get expenseCategories => _categories
      .where((category) => !category.isIncome && !category.isSavings)
      .toList();
  List<Category> get incomeCategories =>
      _categories.where((category) => category.isIncome).toList();
  List<Category> get savingsCategories =>
      _categories.where((category) => category.isSavings).toList();
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    // Don't notify at the start of loading
    _isLoading = true;

    _categories = await _databaseService.getCategories();

    _isLoading = false;
    notifyListeners(); // Only notify once at the end
  }

  Future<void> addCategory(Category category) async {
    await _databaseService.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _databaseService.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _databaseService.deleteCategory(id);
    await loadCategories();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
