// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/providers/account_provider.dart';
import 'package:finance_tracker/providers/transaction_provider.dart';
import 'package:finance_tracker/providers/category_provider.dart';
import 'package:finance_tracker/providers/budget_provider.dart';
import 'package:finance_tracker/services/pdf_service.dart';
import 'package:intl/intl.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({Key? key}) : super(key: key);

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedReportType = 'Transactions';
  File? _generatedFile;

  final List<String> _reportTypes = [
    'Transactions',
    'Accounts Summary',
    'Budgets',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate and export financial reports as PDF',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Report Type Selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedReportType,
                    items: _reportTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReportType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Date Range Selection (only for transaction reports)
                  if (_selectedReportType == 'Transactions') ...[
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_dateFormat.format(_startDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_dateFormat.format(_endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Generate Report Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generate Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions for the generated report
                  if (_generatedFile != null) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Report Generated: ${_generatedFile!.path.split('/').last}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionButton(
                          icon: Icons.visibility,
                          label: 'View',
                          onPressed: () => _openGeneratedFile(),
                        ),
                        _actionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onPressed: () => _shareGeneratedFile(),
                        ),
                        _actionButton(
                          icon: Icons.print,
                          label: 'Print',
                          onPressed: () => _printGeneratedFile(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // Date picker method
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Generate selected report
  Future<void> _generateReport() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get providers
      final accountProvider =
          Provider.of<AccountProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);

      // Make sure data is loaded
      await accountProvider.loadAccounts();
      await transactionProvider.loadTransactions();
      await categoryProvider.loadCategories();
      await budgetProvider.loadBudgets();

      File file;

      switch (_selectedReportType) {
        case 'Transactions':
          // Get transactions within the selected date range
          final transactions = transactionProvider.transactions
              .where((t) =>
                  t.date.isAfter(_startDate) &&
                  t.date.isBefore(_endDate.add(const Duration(days: 1))))
              .toList();

          file = await PdfService.generateTransactionsReport(
            transactions: transactions,
            accounts: accountProvider.accounts,
            categories: categoryProvider.categories,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;

        case 'Accounts Summary':
          file = await PdfService.generateAccountsSummaryReport(
            accounts: accountProvider.accounts,
            transactions: transactionProvider.transactions,
          );
          break;

        case 'Budgets':
          file = await PdfService.generateBudgetsReport(
            budgets: budgetProvider.budgets,
            transactions: transactionProvider.transactions,
            categories: categoryProvider.categories,
          );
          break;

        default:
          throw Exception('Invalid report type selected');
      }

      // Update state with generated file
      setState(() {
        _generatedFile = file;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated successfully')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Open the generated file
  Future<void> _openGeneratedFile() async {
    if (_generatedFile == null) return;

    try {
      await PdfService.openPdf(_generatedFile!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: ${e.toString()}')),
      );
    }
  }

  // Share the generated file
  Future<void> _shareGeneratedFile() async {
    if (_generatedFile == null) return;

    try {
      await PdfService.sharePdf(_generatedFile!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: ${e.toString()}')),
      );
    }
  }

  // Print the generated file
  Future<void> _printGeneratedFile() async {
    if (_generatedFile == null) return;

    try {
      await PdfService.printPdf(_generatedFile!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing file: ${e.toString()}')),
      );
    }
  }

  // Helper method to create action buttons
  Widget _actionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
