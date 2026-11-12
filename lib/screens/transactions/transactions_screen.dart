import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/format_service.dart';
import 'add_transaction_modal.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
      context.read<TransactionProvider>().fetchCategoriesAndTags();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionModal(),
    );
  }

  void _confirmDelete(TransactionItem tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Saldo akun ${tx.account?.name ?? 'terkait'} akan dikembalikan sebesar ${FormatService.rupiah(tx.amount)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<TransactionProvider>().deleteTransaction(tx.id);
              if (success && mounted) {
                context.read<DashboardProvider>().fetchSummary();
                context.read<AccountProvider>().fetchAccounts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi dihapus & saldo dipulihkan')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari catatan atau kategori...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              txProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (val) => txProvider.setSearchQuery(val.trim()),
                ),
                const SizedBox(height: 10),

                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', null, txProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pengeluaran', 'expense', txProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pemasukan', 'income', txProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transfer', 'transfer', txProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),

          // Transactions List
          Expanded(
            child: txProvider.isLoading && txProvider.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : txProvider.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada transaksi ditemukan',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => txProvider.fetchTransactions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: txProvider.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = txProvider.transactions[index];
                            return _buildTransactionCard(tx);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? type, TransactionProvider provider) {
    final isSelected = provider.selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setFilterType(type),
      selectedColor: primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? primary : Theme.of(context).dividerColor),
    );
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';
    final color = isTransfer
        ? AppTheme.accentColor
        : (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor);

    final sign = isTransfer ? '' : (isIncome ? '+ ' : '- ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isTransfer
                ? Icons.swap_horiz
                : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          tx.category?.name ?? (isTransfer ? 'Transfer Antar Dompet' : 'Lainnya'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              isTransfer
                  ? '${tx.account?.name ?? 'Asal'} ➔ ${tx.targetAccount?.name ?? 'Tujuan'}'
                  : (tx.account?.name ?? 'Akun'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (tx.notes != null && tx.notes!.isNotEmpty)
              Text(
                tx.notes!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
              ),
            Text(
              FormatService.dateTime(tx.transactionDate),
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$sign${FormatService.rupiah(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () => _confirmDelete(tx),
            ),
          ],
        ),
      ),
    );
  }
}

