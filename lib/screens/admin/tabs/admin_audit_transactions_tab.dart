import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/format_service.dart';

class AdminAuditTransactionsTab extends StatefulWidget {
  const AdminAuditTransactionsTab({super.key});

  @override
  State<AdminAuditTransactionsTab> createState() => _AdminAuditTransactionsTabState();
}

class _AdminAuditTransactionsTabState extends State<AdminAuditTransactionsTab> {
  final _searchCtrl = TextEditingController();
  String _typeFilter = 'all'; // all, expense, income, transfer

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAuditTransactions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    context.read<AdminProvider>().fetchAuditTransactions(search: val, type: _typeFilter);
  }

  void _onTypeChanged(String type) {
    setState(() => _typeFilter = type);
    context.read<AdminProvider>().fetchAuditTransactions(search: _searchCtrl.text, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Cari catatan atau nama user...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pengeluaran', 'expense'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pemasukan', 'income'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transfer', 'transfer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Transaction list
          Expanded(
            child: admin.isLoading && admin.auditTransactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admin.auditTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Tidak ada riwayat transaksi sistem', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => admin.fetchAuditTransactions(search: _searchCtrl.text, type: _typeFilter),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: admin.auditTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = admin.auditTransactions[index];
                            final userName = tx['user'] != null ? tx['user']['name'] : 'User';
                            final userEmail = tx['user'] != null ? tx['user']['email'] : '';
                            final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                            final type = tx['type'] ?? 'expense';
                            final color = type == 'income'
                                ? AppTheme.incomeColor
                                : (type == 'expense' ? AppTheme.expenseColor : AppTheme.accentColor);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.purple.shade50,
                                              child: Icon(Icons.person, size: 14, color: Colors.purple.shade700),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(width: 4),
                                            Text('($userEmail)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                        Text(
                                          FormatService.rupiah(amount),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            type.toString().toUpperCase(),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${tx['category']?['name'] ?? 'Transfer Antar Akun'} • ${tx['account']?['name'] ?? 'Akun'}${type == 'transfer' ? ' ➔ ${tx['target_account']?['name'] ?? 'Tujuan'}' : ''}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tx['notes'] != null && tx['notes'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Catatan: ${tx['notes']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _typeFilter == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onTypeChanged(type),
      selectedColor: primary.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
      side: BorderSide(color: isSelected ? primary : Theme.of(context).dividerColor),
    );
  }
}

