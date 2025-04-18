import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/providers/transaction_provider.dart';
import 'package:finance_tracker/providers/account_provider.dart';
import 'package:finance_tracker/providers/category_provider.dart';
import 'package:finance_tracker/providers/budget_provider.dart';
import 'package:finance_tracker/providers/monthly_analysis_provider.dart';
import 'package:finance_tracker/providers/theme_provider.dart';
import 'package:finance_tracker/screens/dashboard_screen.dart';
import 'package:finance_tracker/screens/accounts_screen.dart';
import 'package:finance_tracker/screens/add_transaction_screen.dart';
import 'package:finance_tracker/screens/monthly_analysis_screen.dart';
import 'package:finance_tracker/screens/export_reports_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => MonthlyAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Finance Tracker',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExportReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          DashboardScreen(),
          AccountsScreen(),
          MonthlyAnalysisScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Monthly',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildModalContent(context),
            isScrollControlled: true,
          );
        },
      ),
    );
  }

  Widget _buildModalContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.add, color: Colors.white),
            ),
            title: const Text('Add Transaction'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen()),
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.account_balance, color: Colors.white),
            ),
            title: const Text('Add Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountsScreen()),
              ).then((_) {
                // If we're not on the accounts screen, stay where we are
                if (_currentIndex != 1) {
                  _pageController.animateToPage(
                    _currentIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
