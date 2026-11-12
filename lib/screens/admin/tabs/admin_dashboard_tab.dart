import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/format_service.dart';

class AdminDashboardTab extends StatefulWidget {
  final VoidCallback onNavigateToUsers;
  final VoidCallback onNavigateToCategories;

  const AdminDashboardTab({
    super.key,
    required this.onNavigateToUsers,
    required this.onNavigateToCategories,
  });

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.dashboardStats ?? {};

    if (admin.isLoading && admin.dashboardStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalUsers = stats['total_users'] ?? 0;
    final adminCount = stats['admin_count'] ?? 0;
    final userCount = stats['user_count'] ?? 0;
    final totalAccounts = stats['total_accounts'] ?? 0;
    final totalTransactions = stats['total_transactions'] ?? 0;
    final totalVolume = double.tryParse(stats['total_volume']?.toString() ?? '0') ?? 0.0;
    final masterCategoriesCount = stats['master_categories_count'] ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => admin.fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Admin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pusat Kontrol Sistem',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ADMINISTRATOR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola akun pengguna, data master kategori sistem, dan pantau seluruh transaksi aplikasi PlanIt.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 1: STATISTIK RINGKAS
          Text(
            'Statistik Sistem & Database',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                title: 'Total Pengguna',
                value: '$totalUsers',
                subtext: '$adminCount Admin • $userCount User',
                icon: Icons.people_alt,
                color: const Color(0xFF3B82F6),
                onTap: widget.onNavigateToUsers,
              ),
              _buildStatCard(
                title: 'Transaksi Sistem',
                value: '$totalTransactions',
                subtext: '$totalAccounts dompet tercatat',
                icon: Icons.receipt_long,
                color: const Color(0xFF10B981),
              ),
              _buildStatCard(
                title: 'Volume Transaksi',
                value: FormatService.rupiah(totalVolume),
                subtext: 'Akumulasi tercatat',
                icon: Icons.monetization_on,
                color: const Color(0xFFF59E0B),
              ),
              _buildStatCard(
                title: 'Kategori Master',
                value: '$masterCategoriesCount',
                subtext: 'Bawaan untuk semua user',
                icon: Icons.category,
                color: const Color(0xFF8B5CF6),
                onTap: widget.onNavigateToCategories,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // SECTION 2: AKSI CEPAT ADMIN
          Text(
            'Aksi Cepat Administrator',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.onNavigateToUsers,
                  icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                  label: const Text('Kelola User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                  onPressed: widget.onNavigateToCategories,
                  icon: const Icon(Icons.category_outlined, color: Color(0xFF8B5CF6), size: 18),
                  label: const Text('Master Kategori', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SECTION 3: PENGGUNA TERAKHIR DIDAFTARKAN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengguna Terbaru',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToUsers,
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (admin.recentUsers.isEmpty)
            const Text('Belum ada pengguna.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
          else
            ...admin.recentUsers.map((u) {
              final isAdmin = u.isAdmin;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? (isDark ? Colors.purple.shade900.withOpacity(0.5) : Colors.purple.shade100)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin
                          ? (isDark ? Colors.purple.shade200 : Colors.purple.shade700)
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      size: 18,
                    ),
                  ),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(u.email, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? (isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'USER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isAdmin
                            ? (isDark ? Colors.purple.shade200 : Colors.purple.shade700)
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),

          // SECTION 4: RECENT AUDIT TRANSACTIONS
          const Text('Aktivitas Transaksi Sistem Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          if (admin.recentTransactions.isEmpty)
            const Text('Belum ada transaksi di sistem.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
          else
            ...admin.recentTransactions.map((tx) {
              final userName = tx['user'] != null ? tx['user']['name'] : 'User';
              final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
              final type = tx['type'] ?? 'expense';
              final color = type == 'income' ? AppTheme.incomeColor : (type == 'expense' ? AppTheme.expenseColor : AppTheme.accentColor);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(
                      type == 'income' ? Icons.arrow_downward : (type == 'expense' ? Icons.arrow_upward : Icons.swap_horiz),
                      color: color,
                      size: 16,
                    ),
                  ),
                  title: Text('$userName • ${tx['category']?['name'] ?? (type == 'transfer' ? 'Transfer' : 'Umum')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${tx['account']?['name'] ?? 'Akun'} • ${tx['notes'] ?? type}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    FormatService.rupiah(amount),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
