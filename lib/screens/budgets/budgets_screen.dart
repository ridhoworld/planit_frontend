import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/format_service.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().fetchBudgets();
      context.read<TransactionProvider>().fetchCategoriesAndTags();
    });
  }

  void _openAddBudget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddBudgetModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bProvider = context.watch<BudgetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran Pengeluaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buat Anggaran',
            onPressed: _openAddBudget,
          ),
        ],
      ),
      body: bProvider.isLoading && bProvider.budgets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => bProvider.fetchBudgets(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total Budget Summary
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Anggaran Aktif',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Terpakai', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                Text(
                                  FormatService.rupiah(bProvider.totalSpent),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Batas Total', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                Text(
                                  FormatService.rupiah(bProvider.totalLimit),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Daftar Anggaran Kategori',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (bProvider.budgets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Belum ada anggaran yang dibuat', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text(
                            'Buat anggaran untuk membatasi pengeluaran per kategori.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openAddBudget,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Buat Anggaran Sekarang'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...bProvider.budgets.map((b) => _buildBudgetCard(b)),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetCard(Budget b) {
    Color statusColor = AppTheme.incomeColor;
    String statusLabel = 'Aman';

    if (b.percentage >= 100) {
      statusColor = AppTheme.expenseColor;
      statusLabel = 'Melebihi Batas!';
    } else if (b.percentage >= 80) {
      statusColor = AppTheme.warningColor;
      statusLabel = 'Perhatian (>80%)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse((b.category?.color ?? '#3B82F6').replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b.category?.name ?? 'Kategori',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () async {
                    final success = await context.read<BudgetProvider>().deleteBudget(b.id);
                    if (success && context.mounted) {
                      context.read<DashboardProvider>().fetchSummary();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (b.percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terpakai', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      FormatService.rupiah(b.spentAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Persentase', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      '${b.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Sisa Batas', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      FormatService.rupiah(b.remainingAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: b.remainingAmount == 0 ? AppTheme.expenseColor : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetModal extends StatefulWidget {
  const _AddBudgetModal();

  @override
  State<_AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<_AddBudgetModal> {
  final _amountController = TextEditingController();
  int? _selectedCategoryId;
  String _period = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cats = context.read<TransactionProvider>().expenseCategories;
    if (cats.isNotEmpty) {
      _selectedCategoryId = cats.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedCategoryId == null) return;
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);

    final success = await context.read<BudgetProvider>().addBudget(
          categoryId: _selectedCategoryId!,
          amountLimit: amount,
          period: _period,
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.read<DashboardProvider>().fetchSummary();
      Navigator.pop(context);
    } else {
      final msg = context.read<BudgetProvider>().errorMessage ?? 'Gagal membuat anggaran';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<TransactionProvider>().expenseCategories;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Buat Anggaran Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Kategori Pengeluaran'),
              items: categories.map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Batas Nominal Anggaran (Rp)'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _period,
              decoration: const InputDecoration(labelText: 'Periode'),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Mingguan (Weekly)')),
                DropdownMenuItem(value: 'monthly', child: Text('Bulanan (Monthly)')),
                DropdownMenuItem(value: 'yearly', child: Text('Tahunan (Yearly)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _period = val);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Simpan Anggaran'),
            ),
          ],
        ),
      ),
    );
  }
}
