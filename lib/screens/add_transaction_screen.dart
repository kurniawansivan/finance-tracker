// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/models/account.dart';
import 'package:finance_tracker/providers/transaction_provider.dart';
import 'package:finance_tracker/providers/category_provider.dart';
import 'package:finance_tracker/providers/account_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({
    super.key,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late TransactionType _selectedType;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();

  bool _isInit = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      final accountProvider =
          Provider.of<AccountProvider>(context, listen: false);

      // Load categories and accounts if needed
      if (categoryProvider.categories.isEmpty) {
        categoryProvider.loadCategories();
      }

      if (accountProvider.accounts.isEmpty) {
        accountProvider.loadAccounts();
      }

      // If editing an existing transaction, populate the form
      if (widget.transaction != null) {
        _selectedType = widget.transaction!.type;
        _selectedCategoryId = widget.transaction!.categoryId;
        _selectedAccountId = widget.transaction!.accountId;
        _selectedToAccountId = widget.transaction!.toAccountId;
        _selectedDate = widget.transaction!.date;
        _descriptionController.text = widget.transaction!.description;
        _amountController.text = widget.transaction!.amount.toString();
      } else {
        _selectedType = TransactionType.expense;
      }

      _isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if ((_selectedType == TransactionType.expense ||
            _selectedType == TransactionType.income ||
            _selectedType == TransactionType.savings) &&
        _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer &&
        (_selectedAccountId == null || _selectedToAccountId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both from and to accounts')),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer &&
        _selectedAccountId == _selectedToAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('From and To accounts cannot be the same')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    final amount = double.parse(_amountController.text);

    final transaction = Transaction(
      id: widget.transaction?.id,
      amount: amount,
      date: _selectedDate,
      description: _descriptionController.text,
      categoryId: _selectedCategoryId!,
      type: _selectedType,
      accountId: _selectedAccountId,
      toAccountId: _selectedType == TransactionType.transfer
          ? _selectedToAccountId
          : null,
    );

    try {
      if (widget.transaction == null) {
        await transactionProvider.addTransaction(transaction);
      } else {
        await transactionProvider.updateTransaction(transaction);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);

    List<Category> availableCategories = [];
    switch (_selectedType) {
      case TransactionType.expense:
        availableCategories = categoryProvider.expenseCategories;
        break;
      case TransactionType.income:
        availableCategories = categoryProvider.incomeCategories;
        break;
      case TransactionType.transfer:
        availableCategories = categoryProvider.expenseCategories;
        break;
      case TransactionType.savings:
        availableCategories = categoryProvider.savingsCategories;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type Selector
                    const Text(
                      'Transaction Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TransactionType>(
                        selected: {_selectedType},
                        onSelectionChanged: (Set<TransactionType> types) {
                          setState(() {
                            _selectedType = types.first;
                            // Reset category when changing type
                            _selectedCategoryId = null;
                          });
                        },
                        segments: const [
                          ButtonSegment<TransactionType>(
                            value: TransactionType.expense,
                            label:
                                Text('Expense', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.arrow_upward, size: 16),
                          ),
                          ButtonSegment<TransactionType>(
                            value: TransactionType.income,
                            label:
                                Text('Income', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.arrow_downward, size: 16),
                          ),
                          ButtonSegment<TransactionType>(
                            value: TransactionType.transfer,
                            label: Text('Transfer',
                                style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.swap_horiz, size: 16),
                          ),
                          ButtonSegment<TransactionType>(
                            value: TransactionType.savings,
                            label:
                                Text('Savings', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.savings, size: 16),
                          ),
                        ],
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.currency_rupee),
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (availableCategories.isEmpty)
                      const Center(
                        child: Text(
                            'No categories available for this transaction type'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        height: 110, // Keep the increased height
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableCategories.length,
                          itemBuilder: (context, index) {
                            final category = availableCategories[index];
                            final isSelected =
                                category.id == _selectedCategoryId;

                            // Check if category name is longer than 10 characters
                            final bool isLongName = category.name.length > 10;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    right:
                                        10), // Reduced margin for tighter layout
                                width: 70, // Fixed width for each category
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isSelected
                                          ? category.color
                                          : category.color.withOpacity(0.5),
                                      radius: 22, // Slightly smaller icons
                                      child: Icon(
                                        category.icon,
                                        color: Colors.white,
                                        size: 20, // Smaller icon size
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 36, // Fixed height for text area
                                      width: 68, // Slightly wider for text
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          fontSize: isLongName
                                              ? 10
                                              : 11, // Smaller font for longer names
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          letterSpacing: isLongName
                                              ? -0.5
                                              : 0, // Tighter letter spacing for longer names
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Account Selection
                    if (_selectedType != TransactionType.transfer)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (accountProvider.accounts.isEmpty)
                            const Center(
                              child: Text('No accounts available'),
                            )
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              value: _selectedAccountId,
                              hint: const Text('Select Account'),
                              items: accountProvider.accounts.map((account) {
                                return DropdownMenuItem<String>(
                                  value: account.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        account.icon,
                                        color: account.color,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(account.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedAccountId = value;
                                });
                              },
                            ),
                        ],
                      )
                    else
                      // From and To Accounts for Transfer
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (accountProvider.accounts.isEmpty)
                            const Center(
                              child: Text('No accounts available'),
                            )
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              value: _selectedAccountId,
                              hint: const Text('Select From Account'),
                              items: accountProvider.accounts.map((account) {
                                return DropdownMenuItem<String>(
                                  value: account.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        account.icon,
                                        color: account.color,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(account.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedAccountId = value;
                                });
                              },
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'To Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (accountProvider.accounts.isEmpty)
                            const Center(
                              child: Text('No accounts available'),
                            )
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              value: _selectedToAccountId,
                              hint: const Text('Select To Account'),
                              items: accountProvider.accounts.map((account) {
                                return DropdownMenuItem<String>(
                                  value: account.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        account.icon,
                                        color: account.color,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(account.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedToAccountId = value;
                                });
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        child: Text(
                          widget.transaction == null
                              ? 'Add Transaction'
                              : 'Update Transaction',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
