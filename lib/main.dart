import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/planning_provider.dart';
import 'providers/report_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.checkAuth();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => PlanningProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const PlanItApp(),
    ),
  );
}

class PlanItApp extends StatelessWidget {
  const PlanItApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'PlanIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProv.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading && auth.user == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (auth.isAuthenticated) {
            if (auth.isAdmin) {
              return const AdminMainScreen();
            }
            return const MainNavigationScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
