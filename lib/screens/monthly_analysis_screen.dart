import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/providers/monthly_analysis_provider.dart';
import 'package:finance_tracker/providers/category_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyAnalysisScreen extends StatefulWidget {
  const MonthlyAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<MonthlyAnalysisScreen> createState() => _MonthlyAnalysisScreenState();
}

class _MonthlyAnalysisScreenState extends State<MonthlyAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MonthlyAnalysisProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MonthlyAnalysisProvider>(context);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Overview'),
        centerTitle: true,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await provider.loadData();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMonthSelector(provider),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildFinancialSummary(provider),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child:
                          _buildCategoryBreakdown(provider, categoryProvider),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child:
                        _buildTransactionBreakdown(provider, categoryProvider),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector(MonthlyAnalysisProvider provider) {
    final dateFormat = DateFormat('MMMM yyyy');
    final now = DateTime.now();
    final isCurrentMonthMax = provider.currentMonth.year >= now.year &&
        provider.currentMonth.month >= now.month;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => provider.previousMonth(),
            ),
            Text(
              dateFormat.format(provider.currentMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: isCurrentMonthMax ? null : () => provider.nextMonth(),
              color: isCurrentMonthMax ? Colors.grey.shade400 : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(MonthlyAnalysisProvider provider) {
    final summary = provider.currentMonthlySummary;
    if (summary == null) return const SizedBox.shrink();

    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            'Financial Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              title: 'Income',
              amount: summary.totalIncome,
              currency: currency,
              icon: Icons.arrow_upward,
              color: Colors.green,
              growth: provider.getIncomeGrowth(),
            ),
            _buildSummaryCard(
              title: 'Expenses',
              amount: summary.totalExpenses,
              currency: currency,
              icon: Icons.arrow_downward,
              color: Colors.red,
              growth: provider.getExpenseGrowth(),
            ),
            _buildSummaryCard(
              title: 'Savings',
              amount: summary.totalSavings,
              currency: currency,
              icon: Icons.savings,
              color: Colors.blue,
              growth: provider.getSavingsGrowth(),
            ),
            _buildSummaryCard(
              title: 'Balance',
              amount: summary.balance,
              currency: currency,
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
              showGrowth: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required NumberFormat currency,
    required IconData icon,
    required Color color,
    double? growth,
    bool showGrowth = true,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currency.format(amount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (showGrowth && growth != null && growth != 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    growth > 0 ? Icons.trending_up : Icons.trending_down,
                    color: growth > 0 ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${growth.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: growth > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      MonthlyAnalysisProvider provider, CategoryProvider categoryProvider) {
    final summary = provider.currentMonthlySummary;
    if (summary == null || summary.expensesByCategory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No expense data available for this month'),
          ),
        ),
      );
    }

    final sortedExpenses = provider.getSortedCategoryExpenses();
    final categoryPercentages =
        provider.getCategoryPercentages(summary.expensesByCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.3,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(
                        sortedExpenses,
                        categoryPercentages,
                        categoryProvider,
                        summary.totalExpenses,
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      startDegreeOffset: 180,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryLegend(sortedExpenses, categoryProvider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> sortedExpenses,
    Map<String, double> categoryPercentages,
    CategoryProvider categoryProvider,
    double totalExpenses,
  ) {
    final List<PieChartSectionData> sections = [];
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];

    // Create sections for the top categories
    for (var i = 0; i < sortedExpenses.length && i < 5; i++) {
      final entry = sortedExpenses[i];
      final categoryId = entry.key;
      final percent = categoryPercentages[categoryId] ?? 0;
      final category = categoryProvider.getCategoryById(categoryId);
      final color = category?.color ?? colors[i % colors.length];

      sections.add(
        PieChartSectionData(
          color: color.withOpacity(0.8),
          value: entry.value,
          title: '${percent.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Group the rest as "Others" if needed
    if (sortedExpenses.length > 5) {
      final otherValue = sortedExpenses
          .skip(5)
          .fold(0.0, (prev, element) => prev + element.value);
      final otherPercent = (otherValue / totalExpenses) * 100;

      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: otherValue,
          title: '${otherPercent.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildCategoryLegend(
    List<MapEntry<String, double>> sortedExpenses,
    CategoryProvider categoryProvider,
  ) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final displayCount = sortedExpenses.length > 5 ? 5 : sortedExpenses.length;
    final hasOthers = sortedExpenses.length > 5;

    return Column(
      children: [
        ...List.generate(displayCount, (index) {
          final entry = sortedExpenses[index];
          final categoryId = entry.key;
          final amount = entry.value;
          final category = categoryProvider.getCategoryById(categoryId);

          return _buildLegendItem(
            label: category?.name ?? 'Unknown',
            amount: currency.format(amount),
            color: category?.color ?? Colors.grey,
          );
        }),
        if (hasOthers) ...[
          _buildLegendItem(
            label: 'Others',
            amount: currency.format(sortedExpenses
                .skip(5)
                .fold(0.0, (prev, element) => prev + element.value)),
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBreakdown(
    MonthlyAnalysisProvider provider,
    CategoryProvider categoryProvider,
  ) {
    final summary = provider.currentMonthlySummary;
    if (summary == null ||
        (summary.expensesByCategory.isEmpty &&
            summary.incomeByCategory.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTransactionTabs(provider, categoryProvider),
        ],
      ),
    );
  }

  Widget _buildTransactionTabs(
    MonthlyAnalysisProvider provider,
    CategoryProvider categoryProvider,
  ) {
    final summary = provider.currentMonthlySummary;
    if (summary == null) return const SizedBox.shrink();

    final sortedExpenses = provider.getSortedCategoryExpenses();
    final sortedIncome = provider.getSortedCategoryIncome();

    return DefaultTabController(
      length: 2,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Expenses', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('Income', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  // Expenses Tab
                  _buildTransactionList(
                    sortedExpenses,
                    categoryProvider,
                    summary.totalExpenses,
                    Colors.red.shade50,
                  ),
                  // Income Tab
                  _buildTransactionList(
                    sortedIncome,
                    categoryProvider,
                    summary.totalIncome,
                    Colors.green.shade50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    List<MapEntry<String, double>> items,
    CategoryProvider categoryProvider,
    double total,
    Color backgroundColor,
  ) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (items.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final entry = items[index];
          final categoryId = entry.key;
          final amount = entry.value;
          final category = categoryProvider.getCategoryById(categoryId);
          final percentage = (amount / total) * 100;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category?.color ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category?.icon ?? Icons.category,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category?.color ?? Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currency.format(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
