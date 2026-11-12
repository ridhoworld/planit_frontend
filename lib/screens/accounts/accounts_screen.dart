import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/format_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().fetchAccounts();
    });
  }

  void _openAddAccount() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAccountModal(),
    );
  }

  void _openAdjustBalance(Account account) {
    final balanceController = TextEditingController(text: account.currentBalance.toStringAsFixed(0));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sesuaikan Saldo ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan saldo riil saat ini. Sistem akan otomatis mencatat penyesuaian untuk menjaga konsistensi audit.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Baru (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penyesuaian (Opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newBal = double.tryParse(balanceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
              if (newBal == null) return;

              Navigator.pop(ctx);
              final success = await context.read<AccountProvider>().adjustBalance(
                    account.id,
                    newBal,
                    notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
              if (success && mounted) {
                context.read<DashboardProvider>().fetchSummary();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saldo berhasil diperbarui!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accProvider = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet & Rekening'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Akun',
            onPressed: _openAddAccount,
          ),
        ],
      ),
      body: accProvider.isLoading && accProvider.accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => accProvider.fetchAccounts(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total Balance Overview
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Saldo Likuid',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FormatService.rupiah(accProvider.totalBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (accProvider.totalCreditDebt > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Tagihan Kartu Kredit: ${FormatService.rupiah(accProvider.totalCreditDebt)}',
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Daftar Akun Aktif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  ...accProvider.accounts.map((acc) => _buildAccountCard(acc)),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard(Account acc) {
    Color cardColor = AppTheme.primaryColor;
    IconData iconData = Icons.account_balance_wallet;

    switch (acc.type) {
      case 'bank':
        cardColor = const Color(0xFF1E40AF);
        iconData = Icons.account_balance;
        break;
      case 'e-wallet':
        cardColor = const Color(0xFF059669);
        iconData = Icons.phone_android;
        break;
      case 'cash':
        cardColor = const Color(0xFFD97706);
        iconData = Icons.payments;
        break;
      case 'credit_card':
        cardColor = const Color(0xFF7C3AED);
        iconData = Icons.credit_card;
        break;
      case 'investment':
        cardColor = const Color(0xFF0D9488);
        iconData = Icons.trending_up;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: cardColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(acc.typeLabel, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'adjust') {
                      _openAdjustBalance(acc);
                    } else if (val == 'delete') {
                      context.read<AccountProvider>().deleteOrArchiveAccount(acc.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'adjust', child: Text('Sesuaikan Saldo')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus / Arsipkan')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.type == 'credit_card' ? 'Saldo Terutang' : 'Saldo Terkini',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Text(
                      FormatService.rupiah(acc.currentBalance),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                if (acc.creditLimit != null && acc.creditLimit! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Sisa Limit', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      Text(
                        FormatService.rupiah(acc.creditLimit! - acc.currentBalance),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
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

class _AddAccountModal extends StatefulWidget {
  const _AddAccountModal();

  @override
  State<_AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<_AddAccountModal> {
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController(text: '0');
  final _creditLimitController = TextEditingController();
  String _type = 'bank';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final initBal = double.tryParse(_initialBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final creditLimit = _type == 'credit_card'
        ? double.tryParse(_creditLimitController.text.replaceAll(RegExp(r'[^0-9.]'), ''))
        : null;

    setState(() => _isSubmitting = true);

    final success = await context.read<AccountProvider>().addAccount(
          name: name,
          type: _type,
          initialBalance: initBal,
          creditLimit: creditLimit,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.read<DashboardProvider>().fetchSummary();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Tambah Dompet / Rekening',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Akun (mis. BCA, GoPay, Tunai)'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Jenis Akun'),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Rekening Bank')),
                DropdownMenuItem(value: 'e-wallet', child: Text('Dompet Digital (E-Wallet)')),
                DropdownMenuItem(value: 'cash', child: Text('Uang Tunai (Cash)')),
                DropdownMenuItem(value: 'credit_card', child: Text('Kartu Kredit (Credit Card)')),
                DropdownMenuItem(value: 'investment', child: Text('Rekening Investasi (RDL / Sekuritas)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _initialBalanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _type == 'credit_card' ? 'Saldo Terutang Awal (Rp)' : 'Saldo Awal (Rp)',
              ),
            ),
            if (_type == 'credit_card') ...[
              const SizedBox(height: 14),
              TextField(
                controller: _creditLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Batas / Limit Kredit (Rp)'),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Simpan Akun'),
            ),
          ],
        ),
      ),
    );
  }
}

