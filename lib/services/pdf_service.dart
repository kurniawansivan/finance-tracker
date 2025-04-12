// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/models/account.dart';
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/models/budget.dart';

class PdfService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  // Generate transactions report as PDF
  static Future<File> generateTransactionsReport({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    required DateTime startDate,
    required DateTime endDate,
    String title = 'Transactions Report',
  }) async {
    final pdf = pw.Document();

    // Get account and category maps for quick lookup
    final accountMap = {for (var a in accounts) a.id: a};
    final categoryMap = {for (var c in categories) c.id: c};

    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildReportHeader(title, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildTransactionsSummary(transactions),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, accountMap, categoryMap),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    return await _saveDocument(title, pdf);
  }

  // Generate account summary report as PDF
  static Future<File> generateAccountsSummaryReport({
    required List<Account> accounts,
    required List<Transaction> transactions,
    String title = 'Accounts Summary Report',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Calculate account balances
    final accountBalances = <String, double>{};
    for (var account in accounts) {
      accountBalances[account.id] = account.initialBalance;
    }

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        if (transaction.accountId != null) {
          accountBalances[transaction.accountId!] =
              (accountBalances[transaction.accountId!] ?? 0) +
                  transaction.amount;
        }
      } else if (transaction.type == TransactionType.expense) {
        if (transaction.accountId != null) {
          accountBalances[transaction.accountId!] =
              (accountBalances[transaction.accountId!] ?? 0) -
                  transaction.amount;
        }
      } else if (transaction.type == TransactionType.transfer) {
        if (transaction.accountId != null) {
          accountBalances[transaction.accountId!] =
              (accountBalances[transaction.accountId!] ?? 0) -
                  transaction.amount;
        }
        if (transaction.toAccountId != null) {
          accountBalances[transaction.toAccountId!] =
              (accountBalances[transaction.toAccountId!] ?? 0) +
                  transaction.amount;
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildReportHeader(title, null, null),
          pw.SizedBox(height: 20),
          _buildAccountsSummary(accounts, accountBalances),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Generated on ${_dateFormat.format(now)} - Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    );

    return await _saveDocument(title, pdf);
  }

  // Generate budgets report as PDF
  static Future<File> generateBudgetsReport({
    required List<Budget> budgets,
    required List<Transaction> transactions,
    required List<Category> categories,
    String title = 'Budgets Report',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Get category map for quick lookup
    final categoryMap = {for (var c in categories) c.id: c};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildReportHeader(title, null, null),
          pw.SizedBox(height: 20),
          _buildBudgetsSummary(budgets, transactions, categoryMap),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Generated on ${_dateFormat.format(now)} - Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    );

    return await _saveDocument(title, pdf);
  }

  // Build header for reports
  static pw.Widget _buildReportHeader(
      String title, DateTime? startDate, DateTime? endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        if (startDate != null && endDate != null)
          pw.Text(
            'Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        pw.Divider(),
      ],
    );
  }

  // Build transactions summary section
  static pw.Widget _buildTransactionsSummary(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    double totalTransfers = 0;
    double totalSavings = 0;

    for (var transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          totalIncome += transaction.amount;
          break;
        case TransactionType.expense:
          totalExpense += transaction.amount;
          break;
        case TransactionType.transfer:
          totalTransfers += transaction.amount;
          break;
        case TransactionType.savings:
          totalSavings += transaction.amount;
          break;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Transactions: ${transactions.length}'),
              pw.Text(
                  'Balance: ${_currencyFormat.format(totalIncome - totalExpense)}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Income: ${_currencyFormat.format(totalIncome)}'),
              pw.Text('Expenses: ${_currencyFormat.format(totalExpense)}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Transfers: ${_currencyFormat.format(totalTransfers)}'),
              pw.Text('Savings: ${_currencyFormat.format(totalSavings)}'),
            ],
          ),
        ],
      ),
    );
  }

  // Build transactions table for PDF
  static pw.Widget _buildTransactionsTable(
    List<Transaction> transactions,
    Map<String, Account> accountMap,
    Map<String, Category> categoryMap,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(4), // Description
        2: const pw.FlexColumnWidth(2), // Category
        3: const pw.FlexColumnWidth(2), // Account
        4: const pw.FlexColumnWidth(2), // Amount
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeaderCell('Date'),
            _tableHeaderCell('Description'),
            _tableHeaderCell('Category'),
            _tableHeaderCell('Account'),
            _tableHeaderCell('Amount'),
          ],
        ),
        // Table Rows
        ...transactions.map((transaction) {
          final category =
              categoryMap[transaction.categoryId]?.name ?? 'Unknown';
          final account = transaction.accountId != null
              ? accountMap[transaction.accountId]?.name ?? 'Unknown'
              : 'N/A';

          PdfColor amountColor;
          switch (transaction.type) {
            case TransactionType.income:
              amountColor = PdfColors.green700;
              break;
            case TransactionType.expense:
              amountColor = PdfColors.red700;
              break;
            default:
              amountColor = PdfColors.black;
              break;
          }

          return pw.TableRow(
            children: [
              _tableCell(_dateFormat.format(transaction.date)),
              _tableCell(transaction.description),
              _tableCell(category),
              _tableCell(account),
              _tableCellAmount(
                transaction.type == TransactionType.expense
                    ? '-${_currencyFormat.format(transaction.amount)}'
                    : _currencyFormat.format(transaction.amount),
                color: amountColor,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Build accounts summary for PDF
  static pw.Widget _buildAccountsSummary(
      List<Account> accounts, Map<String, double> balances) {
    double totalBalance = 0;

    for (var account in accounts) {
      if (account.includeInTotal) {
        totalBalance += balances[account.id] ?? 0;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total Balance: ${_currencyFormat.format(totalBalance)}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Name
            1: const pw.FlexColumnWidth(2), // Type
            2: const pw.FlexColumnWidth(2), // Initial Balance
            3: const pw.FlexColumnWidth(2), // Current Balance
          },
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeaderCell('Account Name'),
                _tableHeaderCell('Type'),
                _tableHeaderCell('Initial Balance'),
                _tableHeaderCell('Current Balance'),
              ],
            ),
            // Table Rows
            ...accounts.map((account) {
              final currentBalance =
                  balances[account.id] ?? account.initialBalance;

              return pw.TableRow(
                children: [
                  _tableCell(account.name),
                  _tableCell(account.type.toString().split('.').last),
                  _tableCell(_currencyFormat.format(account.initialBalance)),
                  _tableCellAmount(
                    _currencyFormat.format(currentBalance),
                    color: currentBalance >= 0
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Build budgets summary for PDF
  static pw.Widget _buildBudgetsSummary(
    List<Budget> budgets,
    List<Transaction> transactions,
    Map<String, Category> categoryMap,
  ) {
    // Calculate spent amounts for each budget's category
    final spentAmounts = <String, double>{};

    for (var budget in budgets) {
      if (budget.categoryId != null) {
        double spent = 0;

        // Check transactions in the budget period
        for (var transaction in transactions) {
          // Only count expenses
          if (transaction.type == TransactionType.expense &&
              transaction.categoryId == budget.categoryId) {
            // Check if transaction is within budget period
            bool isInPeriod = _isTransactionInBudgetPeriod(transaction, budget);
            if (isInPeriod) {
              spent += transaction.amount;
            }
          }
        }

        spentAmounts[budget.id] = spent;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budget Overview',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Name
            1: const pw.FlexColumnWidth(2), // Category
            2: const pw.FlexColumnWidth(2), // Amount
            3: const pw.FlexColumnWidth(2), // Spent
            4: const pw.FlexColumnWidth(1), // Progress
          },
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeaderCell('Budget Name'),
                _tableHeaderCell('Category'),
                _tableHeaderCell('Budget Amount'),
                _tableHeaderCell('Spent'),
                _tableHeaderCell('%'),
              ],
            ),
            // Table Rows
            ...budgets.map((budget) {
              final categoryName = budget.categoryId != null
                  ? categoryMap[budget.categoryId]?.name ?? 'All Categories'
                  : 'All Categories';
              final spent = spentAmounts[budget.id] ?? 0;
              final progress = budget.amount > 0
                  ? '${(spent / budget.amount * 100).toStringAsFixed(0)}%'
                  : '0%';
              final isOverBudget = spent > budget.amount;

              return pw.TableRow(
                children: [
                  _tableCell(budget.name),
                  _tableCell(categoryName),
                  _tableCell(_currencyFormat.format(budget.amount)),
                  _tableCellAmount(
                    _currencyFormat.format(spent),
                    color: isOverBudget ? PdfColors.red700 : PdfColors.black,
                  ),
                  _tableCellAmount(
                    progress,
                    color: isOverBudget ? PdfColors.red700 : PdfColors.black,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Check if a transaction falls within a budget period
  static bool _isTransactionInBudgetPeriod(
      Transaction transaction, Budget budget) {
    final transactionDate = transaction.date;

    // If budget has a defined end date
    if (budget.endDate != null) {
      return transactionDate.isAfter(budget.startDate) &&
          transactionDate.isBefore(budget.endDate!);
    }

    // For monthly budgets without end date, check if it falls in the current month
    if (budget.period == 0) {
      // Assuming 0 is monthly
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);

      return transactionDate.isAfter(currentMonthStart) &&
          transactionDate.isBefore(nextMonthStart);
    }

    // For other cases, just check if after start date
    return transactionDate.isAfter(budget.startDate);
  }

  // Helper methods for table cells
  static pw.Widget _tableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCellAmount(String text, {required PdfColor color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Save PDF document to file
  static Future<File> _saveDocument(String title, pw.Document pdf) async {
    // Replace spaces and special characters in filename
    final fileName =
        '${title.replaceAll(' ', '_').replaceAll('/', '-')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    // Get document directory
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    // Save the PDF
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Open PDF file
  static Future<void> openPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open PDF: ${result.message}');
    }
  }

  // Share PDF file
  static Future<void> sharePdf(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'Finance report generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }

  // Print PDF file
  static Future<void> printPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (_) async => file.readAsBytes(),
    );
  }
}
