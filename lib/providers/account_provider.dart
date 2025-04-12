import 'package:flutter/foundation.dart';
import 'package:finance_tracker/models/account.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/services/database_service.dart';

class AccountProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Account> _accounts = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;

  Future<void> loadAccounts() async {
    // Don't notify at the start of loading
    _isLoading = true;

    _accounts = await _databaseService.getAccounts();

    _isLoading = false;
    notifyListeners(); // Only notify once at the end
  }

  Future<void> addAccount(Account account) async {
    await _databaseService.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    await _databaseService.updateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _databaseService.deleteAccount(id);
    await loadAccounts();
  }

  Future<Map<String, double>> getAccountBalances(
      List<Transaction> transactions) async {
    final Map<String, double> balances = {};

    // Initialize balances with initial account balances
    for (final account in _accounts) {
      balances[account.id] = account.initialBalance;
    }

    // Update balances based on transactions
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.accountId != null) {
        balances[transaction.accountId!] =
            (balances[transaction.accountId!] ?? 0) + transaction.amount;
      } else if (transaction.type == TransactionType.expense &&
          transaction.accountId != null) {
        balances[transaction.accountId!] =
            (balances[transaction.accountId!] ?? 0) - transaction.amount;
      } else if (transaction.type == TransactionType.transfer) {
        if (transaction.accountId != null) {
          balances[transaction.accountId!] =
              (balances[transaction.accountId!] ?? 0) - transaction.amount;
        }
        if (transaction.toAccountId != null) {
          balances[transaction.toAccountId!] =
              (balances[transaction.toAccountId!] ?? 0) + transaction.amount;
        }
      } else if (transaction.type == TransactionType.savings &&
          transaction.accountId != null) {
        balances[transaction.accountId!] =
            (balances[transaction.accountId!] ?? 0) - transaction.amount;
      }
    }

    return balances;
  }

  double getTotalBalance(Map<String, double> balances) {
    double total = 0;
    for (final account in _accounts) {
      if (account.includeInTotal && balances.containsKey(account.id)) {
        total += balances[account.id]!;
      }
    }
    return total;
  }

  double getTotalSavings(Map<String, double> balances) {
    double total = 0;
    for (final account in _accounts) {
      if (account.type == AccountType.savings &&
          balances.containsKey(account.id)) {
        total += balances[account.id]!;
      }
    }
    return total;
  }

  findAccountById(String s) {}
}
