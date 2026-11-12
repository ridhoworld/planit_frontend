import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import '../main_navigation_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_users_screen.dart';
import 'tabs/admin_audit_transactions_tab.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_master_categories_tab.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      AdminDashboardTab(
        onNavigateToUsers: () => _goToTab(1),
        onNavigateToCategories: () => _goToTab(2),
      ),
      const AdminUsersScreen(showAppBar: false),
      const AdminMasterCategoriesTab(),
      const AdminAuditTransactionsTab(),
    ];

    final titles = [
      'Dashboard Administrator',
      'Manajemen Pengguna',
      'Data Master Kategori',
      'Audit Transaksi Sistem',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  titles[_currentIndex],
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.purple.shade900.withOpacity(0.5) : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PORTAL ADMIN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.purple.shade200 : Colors.purple.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${auth.user?.name ?? 'Admin'} • ${auth.user?.email ?? ''}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Profile & Settings
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil & Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          // Switch to User Finance Mode Button
          IconButton(
            icon: const Icon(Icons.person_pin_circle_outlined),
            tooltip: 'Beralih ke Tampilan Pengguna Pribadi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Keluar',
            onPressed: () => LogoutConfirmationDialog.show(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: isDark ? const Color(0xFF6D28D9).withOpacity(0.3) : Colors.purple.shade100,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9)),
            label: 'Ringkasan',
          ),
          NavigationDestination(
            icon: const Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9)),
            label: 'Pengguna',
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9)),
            label: 'Kategori',
          ),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9)),
            label: 'Audit Data',
          ),
        ],
      ),
    );
  }
}
