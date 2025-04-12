// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/providers/transaction_provider.dart';
import 'package:finance_tracker/providers/account_provider.dart';
import 'package:finance_tracker/providers/category_provider.dart';
import 'package:finance_tracker/providers/budget_provider.dart';
import 'package:finance_tracker/screens/transaction_list_screen.dart'; // Add this import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInit = false;
  bool _isLoading = false;
  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  Map<String, double> _accountBalances = {};

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _loadData();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load all providers data
    await Provider.of<AccountProvider>(context, listen: false).loadAccounts();
    await Provider.of<CategoryProvider>(context, listen: false)
        .loadCategories();
    await Provider.of<TransactionProvider>(context, listen: false)
        .loadTransactions();
    await Provider.of<BudgetProvider>(context, listen: false).loadBudgets();

    // Get account balances
    final transactions =
        Provider.of<TransactionProvider>(context, listen: false).transactions;
    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);
    _accountBalances = await accountProvider.getAccountBalances(transactions);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    final totalBalance = accountProvider.getTotalBalance(_accountBalances);
    final totalSavings = accountProvider.getTotalSavings(_accountBalances);
    final totalIncome = transactionProvider.getTotalIncome();
    final totalExpenses = transactionProvider.getTotalExpenses();

    final budgetProgress = budgetProvider
        .calculateBudgetProgress(transactionProvider.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Summary Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(totalBalance),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Income'),
                                    Text(
                                      currencyFormat.format(totalIncome),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Expenses'),
                                    Text(
                                      currencyFormat.format(totalExpenses),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Savings'),
                                    Text(
                                      currencyFormat.format(totalSavings),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Expense Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Expense Pie Chart
                    if (totalExpenses > 0)
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _getExpenseSections(
                              transactionProvider,
                              categoryProvider,
                            ),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No expense data available'),
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Recent Transactions List
                    if (transactionProvider.transactions.isNotEmpty)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: transactionProvider.transactions.length > 5
                            ? 5
                            : transactionProvider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              transactionProvider.transactions[index];
                          final category = categoryProvider
                              .getCategoryById(transaction.categoryId);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: category?.color ?? Colors.grey,
                              child: Icon(
                                category?.icon ?? Icons.receipt,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(transaction.description),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(transaction.date),
                            ),
                            trailing: Text(
                              currencyFormat.format(transaction.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: transaction.type ==
                                        TransactionType.expense
                                    ? Colors.red
                                    : transaction.type == TransactionType.income
                                        ? Colors.green
                                        : Colors.blue,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No transactions available'),
                        ),
                      ),

                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionListScreen(),
                            ),
                          );
                        },
                        child: const Text('View All Transactions'),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Budget Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Budget Progress
                    if (budgetProvider.budgets.isNotEmpty)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: budgetProvider.budgets.length,
                        itemBuilder: (context, index) {
                          final budget = budgetProvider.budgets[index];
                          final progress = budgetProgress[budget.id] ?? 0.0;
                          final category = budget.categoryId != null
                              ? categoryProvider
                                  .getCategoryById(budget.categoryId!)
                              : null;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (category != null)
                                        CircleAvatar(
                                          backgroundColor: category.color,
                                          radius: 12,
                                          child: Icon(
                                            category.icon,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        budget.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyle(
                                          color: progress > 0.9
                                              ? Colors.red
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress > 0.9
                                          ? Colors.red
                                          : progress > 0.7
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Budget: ${currencyFormat.format(budget.amount)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No budgets available'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  List<PieChartSectionData> _getExpenseSections(
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider,
  ) {
    final expensesByCategory = transactionProvider.getExpensesByCategory();
    final totalExpenses = transactionProvider.getTotalExpenses();

    if (totalExpenses <= 0) {
      return [];
    }

    // Convert to list and sort by amount
    final categoryExpenses = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 categories
    final topCategories = categoryExpenses.take(5).toList();

    // Calculate "Others" if needed
    double othersAmount = 0;
    if (categoryExpenses.length > 5) {
      for (int i = 5; i < categoryExpenses.length; i++) {
        othersAmount += categoryExpenses[i].value;
      }
    }

    // Create sections for the pie chart
    final List<PieChartSectionData> sections = [];

    // Add top categories
    for (final entry in topCategories) {
      final category = categoryProvider.getCategoryById(entry.key);
      final percentage = entry.value / totalExpenses;

      sections.add(PieChartSectionData(
        color: category?.color ?? Colors.grey,
        value: entry.value,
        title: '${(percentage * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    // Add "Others" section if needed
    if (othersAmount > 0) {
      final percentage = othersAmount / totalExpenses;
      sections.add(PieChartSectionData(
        color: Colors.grey,
        value: othersAmount,
        title: '${(percentage * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return sections;
  }
}
