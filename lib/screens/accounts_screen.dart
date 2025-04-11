import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/models/account.dart';
import 'package:finance_tracker/providers/account_provider.dart';
import 'package:finance_tracker/providers/transaction_provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await accountProvider.loadAccounts();
          await transactionProvider.loadTransactions();
        },
        child: FutureBuilder<Map<String, double>>(
          future: accountProvider
              .getAccountBalances(transactionProvider.transactions),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                  child: Text('Error loading account balances'));
            }

            final accountBalances = snapshot.data!;
            final totalBalance =
                accountProvider.getTotalBalance(accountBalances);

            return Column(
              children: [
                // Total balance card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
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
                      ],
                    ),
                  ),
                ),

                // Account list
                Expanded(
                  child: accountProvider.accounts.isEmpty
                      ? const Center(
                          child: Text('No accounts added yet'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: accountProvider.accounts.length,
                          itemBuilder: (context, index) {
                            final account = accountProvider.accounts[index];
                            final balance = accountBalances[account.id] ??
                                account.initialBalance;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: account.color,
                                  child: Icon(
                                    account.icon,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle:
                                    Text(_getAccountTypeText(account.type)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(balance),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: balance < 0
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    if (!account.includeInTotal)
                                      const Text(
                                        'Not in total',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  _showAccountOptions(context, account);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddEditAccount(context);
        },
      ),
    );
  }

  String _getAccountTypeText(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.investment:
        return 'Investment';
      case AccountType.savings:
        return 'Savings Account';
      default:
        return 'Account';
    }
  }

  void _showAccountOptions(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Account'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddEditAccount(context, account: account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDeleteConfirmation(context, account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete ${account.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AccountProvider>(context, listen: false)
                    .deleteAccount(account.id);
                Navigator.of(ctx).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditAccount(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AddEditAccountForm(account: account);
      },
    );
  }
}

class AddEditAccountForm extends StatefulWidget {
  final Account? account;

  const AddEditAccountForm({
    super.key,
    this.account,
  });

  @override
  State<AddEditAccountForm> createState() => _AddEditAccountFormState();
}

class _AddEditAccountFormState extends State<AddEditAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  late AccountType _selectedType;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late bool _includeInTotal;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.account != null) {
      // Editing an existing account
      _nameController.text = widget.account!.name;
      _initialBalanceController.text =
          widget.account!.initialBalance.toString();
      _selectedType = widget.account!.type;
      _selectedColor = widget.account!.color;
      _selectedIcon = widget.account!.icon;
      _includeInTotal = widget.account!.includeInTotal;
    } else {
      // Creating a new account
      _selectedType = AccountType.bank;
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.account_balance;
      _includeInTotal = true;
      _initialBalanceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accountProvider =
          Provider.of<AccountProvider>(context, listen: false);
      final account = Account(
        id: widget.account?.id,
        name: _nameController.text,
        initialBalance: double.parse(_initialBalanceController.text),
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
        includeInTotal: _includeInTotal,
      );

      if (widget.account == null) {
        await accountProvider.addAccount(account);
      } else {
        await accountProvider.updateAccount(account);
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
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account == null ? 'Add Account' : 'Edit Account',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                items: AccountType.values.map((type) {
                  return DropdownMenuItem<AccountType>(
                    value: type,
                    child: Text(_getAccountTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Update icon based on selected type
                      switch (value) {
                        case AccountType.cash:
                          _selectedIcon = Icons.money;
                          _selectedColor = Colors.green;
                          break;
                        case AccountType.bank:
                          _selectedIcon = Icons.account_balance;
                          _selectedColor = Colors.blue;
                          break;
                        case AccountType.creditCard:
                          _selectedIcon = Icons.credit_card;
                          _selectedColor = Colors.purple;
                          break;
                        case AccountType.investment:
                          _selectedIcon = Icons.trending_up;
                          _selectedColor = Colors.orange;
                          break;
                        case AccountType.savings:
                          _selectedIcon = Icons.savings;
                          _selectedColor = Colors.teal;
                          break;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the initial balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _colorOption(Colors.red),
                    _colorOption(Colors.orange),
                    _colorOption(Colors.amber),
                    _colorOption(Colors.green),
                    _colorOption(Colors.teal),
                    _colorOption(Colors.blue),
                    _colorOption(Colors.indigo),
                    _colorOption(Colors.purple),
                    _colorOption(Colors.pink),
                    _colorOption(Colors.brown),
                    _colorOption(Colors.grey),
                    _colorOption(Colors.blueGrey),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _iconOption(Icons.account_balance),
                    _iconOption(Icons.credit_card),
                    _iconOption(Icons.savings),
                    _iconOption(Icons.money),
                    _iconOption(Icons.wallet),
                    _iconOption(Icons.payments),
                    _iconOption(Icons.account_balance_wallet),
                    _iconOption(Icons.currency_exchange),
                    _iconOption(Icons.trending_up),
                    _iconOption(Icons.attach_money),
                    _iconOption(Icons.euro),
                    _iconOption(Icons.currency_bitcoin),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Include in Total Balance'),
                value: _includeInTotal,
                onChanged: (value) {
                  setState(() {
                    _includeInTotal = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.account == null
                              ? 'Add Account'
                              : 'Update Account',
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

  Widget _colorOption(Color color) {
    final isSelected = _selectedColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }

  Widget _iconOption(IconData icon) {
    final isSelected = _selectedIcon.codePoint == icon.codePoint;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIcon = icon;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }

  String _getAccountTypeText(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.investment:
        return 'Investment';
      case AccountType.savings:
        return 'Savings Account';
      default:
        return 'Account';
    }
  }
}
