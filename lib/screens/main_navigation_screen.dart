import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'accounts/accounts_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'planning/planning_screen.dart';
import 'reports/reports_screen.dart';
import 'transactions/transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    BudgetsScreen(),
    PlanningScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: activeColor),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: activeColor),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: activeColor),
            label: 'Dompet',
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: activeColor),
            label: 'Anggaran',
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: activeColor),
            label: 'Rencana',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: activeColor),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

