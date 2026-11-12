import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/debt.dart';
import '../../models/financial_goal.dart';
import '../../models/investment.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/planning_provider.dart';
import '../../services/format_service.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanningProvider>().fetchAllPlanning();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rencana & Aset'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tujuan (Goals)'),
            Tab(text: 'Utang-Piutang'),
            Tab(text: 'Investasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GoalsTab(),
          _DebtsTab(),
          _InvestmentsTab(),
        ],
      ),
    );
  }
}

// ==========================================
// 1. FINANCIAL GOALS TAB
// ==========================================
class _GoalsTab extends StatelessWidget {
  const _GoalsTab();

  void _openAddGoal(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final initialController = TextEditingController(text: '0');
    DateTime? deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Buat Tujuan Keuangan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Target (mis. Dana Darurat, DP Rumah)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Nominal (Rp)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: initialController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tabungan Awal (Opsional)'),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 180)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) {
                    setModalState(() => deadline = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(ctx).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(deadline != null ? 'Batas Waktu: ${FormatService.date(deadline)}' : 'Pilih Batas Waktu (Deadline)'),
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final target = double.tryParse(targetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  final init = double.tryParse(initialController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

                  if (name.isEmpty || target <= 0) return;

                  Navigator.pop(ctx);
                  await context.read<PlanningProvider>().addGoal(
                        name: name,
                        targetAmount: target,
                        initialAmount: init,
                        deadline: deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
                      );
                  if (context.mounted) {
                    context.read<DashboardProvider>().fetchSummary();
                  }
                },
                child: const Text('Simpan Target'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDepositModal(BuildContext context, FinancialGoal goal) {
    final amountController = TextEditingController();
    int? selectedAccountId;

    final accounts = context.read<AccountProvider>().activeAccounts;
    if (accounts.isNotEmpty) {
      selectedAccountId = accounts.first.id;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nabung ke ${goal.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Sisa target: ${FormatService.rupiah(goal.remainingAmount)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nominal Setoran (Rp)'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Potong dari Dompet (Opsional)'),
                items: accounts.map((a) {
                  return DropdownMenuItem<int>(
                    value: a.id,
                    child: Text('${a.name} (${FormatService.rupiah(a.currentBalance)})'),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedAccountId = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  if (amount <= 0) return;

                  Navigator.pop(ctx);
                  await context.read<PlanningProvider>().depositGoal(goal.id, amount, selectedAccountId);
                  if (context.mounted) {
                    context.read<DashboardProvider>().fetchSummary();
                    context.read<AccountProvider>().fetchAccounts();
                  }
                },
                child: const Text('Setor Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planning = context.watch<PlanningProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddGoal(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Target Baru', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () => planning.fetchGoals(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Summary banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Tabungan Terkumpul', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    FormatService.rupiah(planning.totalGoalSaved),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dari total target: ${FormatService.rupiah(planning.totalGoalTarget)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (planning.goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.flag_outlined, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('Belum ada target keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Buat target tabungan seperti Dana Darurat atau DP Rumah.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              )
            else
              ...planning.goals.map((g) => _buildGoalCard(context, g)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, FinancialGoal g) {
    final isDone = g.status == 'completed' || g.percentage >= 100;
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
                  child: Text(
                    g.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.incomeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.incomeColor),
                        SizedBox(width: 4),
                        Text('Tercapai', style: TextStyle(color: AppTheme.incomeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  Text(
                    '${g.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (g.percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(isDone ? AppTheme.incomeColor : AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terkumpul', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(FormatService.rupiah(g.currentAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Target', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(FormatService.rupiah(g.targetAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
            if (g.suggestedMonthly > 0 && !isDone) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saran nabung: ${FormatService.rupiah(g.suggestedMonthly)} / bulan hingga deadline.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isDone) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openDepositModal(context, g),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Setor Tabungan'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. DEBTS & RECEIVABLES TAB
// ==========================================
class _DebtsTab extends StatelessWidget {
  const _DebtsTab();

  void _openAddDebt(BuildContext context) {
    final partyController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String type = 'payable';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Catat Utang / Piutang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Jenis'),
                items: const [
                  DropdownMenuItem(value: 'payable', child: Text('Utang Saya (Kita berutang ke orang lain)')),
                  DropdownMenuItem(value: 'receivable', child: Text('Piutang Saya (Orang lain berutang ke kita)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => type = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: partyController,
                decoration: const InputDecoration(labelText: 'Nama Pihak (mis. Bank Mandiri, Budi)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Pokok (Rp)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Catatan / Cicilan (Opsional)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final party = partyController.text.trim();
                  final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  if (party.isEmpty || amount <= 0) return;

                  Navigator.pop(ctx);
                  await context.read<PlanningProvider>().addDebt(
                        type: type,
                        partyName: party,
                        totalAmount: amount,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                  if (context.mounted) {
                    context.read<DashboardProvider>().fetchSummary();
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPaymentModal(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    int? selectedAccountId;
    final accounts = context.read<AccountProvider>().activeAccounts;
    if (accounts.isNotEmpty) selectedAccountId = accounts.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                debt.isPayable ? 'Bayar Utang: ${debt.partyName}' : 'Catat Penerimaan: ${debt.partyName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Sisa pokok: ${FormatService.rupiah(debt.remainingAmount)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nominal Pembayaran (Rp)'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: selectedAccountId,
                decoration: InputDecoration(
                  labelText: debt.isPayable ? 'Potong dari Dompet' : 'Masuk ke Dompet',
                ),
                items: accounts.map((a) {
                  return DropdownMenuItem<int>(
                    value: a.id,
                    child: Text('${a.name} (${FormatService.rupiah(a.currentBalance)})'),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedAccountId = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  if (amount <= 0) return;

                  Navigator.pop(ctx);
                  await context.read<PlanningProvider>().addDebtPayment(
                        debt.id,
                        amount,
                        DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        selectedAccountId,
                      );
                  if (context.mounted) {
                    context.read<DashboardProvider>().fetchSummary();
                    context.read<AccountProvider>().fetchAccounts();
                  }
                },
                child: const Text('Simpan Pembayaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planning = context.watch<PlanningProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDebt(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat Baru', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () => planning.fetchDebts(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Utang Kita', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          FormatService.rupiah(planning.totalPayable),
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Piutang Kita', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          FormatService.rupiah(planning.totalReceivable),
                          style: const TextStyle(color: Color(0xFF166534), fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (planning.debts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.handshake_outlined, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('Tidak ada utang atau piutang aktif', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              ...planning.debts.map((d) => _buildDebtCard(context, d)),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt d) {
    final isLunas = d.remainingAmount <= 0;
    final color = d.isPayable ? AppTheme.expenseColor : AppTheme.incomeColor;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        d.isPayable ? 'Utang ke pihak luar' : 'Piutang ke teman/klien',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (isLunas)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Lunas', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else
                  Text(
                    FormatService.rupiah(d.remainingAmount),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total pokok: ${FormatService.rupiah(d.totalAmount)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                if (d.dueDate != null)
                  Text('Tempo: ${FormatService.date(d.dueDate)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
            if (!isLunas) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openPaymentModal(context, d),
                icon: const Icon(Icons.payment, size: 16),
                label: Text(d.isPayable ? 'Bayar Cicilan / Lunas' : 'Catat Pelunasan Masuk'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. INVESTMENTS TAB
// ==========================================
class _InvestmentsTab extends StatelessWidget {
  const _InvestmentsTab();

  void _openAddInvestment(BuildContext context) {
    final nameController = TextEditingController();
    final unitsController = TextEditingController();
    final buyPriceController = TextEditingController();
    final currentPriceController = TextEditingController();
    String type = 'stock';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tambah Aset Investasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Jenis Aset'),
                items: const [
                  DropdownMenuItem(value: 'stock', child: Text('Saham (Stock)')),
                  DropdownMenuItem(value: 'mutual_fund', child: Text('Reksadana (Mutual Fund)')),
                  DropdownMenuItem(value: 'gold', child: Text('Emas Logam Mulia (Gold)')),
                  DropdownMenuItem(value: 'crypto', child: Text('Kripto (Crypto)')),
                  DropdownMenuItem(value: 'property', child: Text('Properti (Property)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => type = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Aset (mis. BBCA, Emas Antam)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Unit / Lot / Gram'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: buyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Beli Rata2 (Rp)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: currentPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Pasar Kini (Rp)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final units = double.tryParse(unitsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  final buyPrice = double.tryParse(buyPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  final curPrice = double.tryParse(currentPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? buyPrice;

                  if (name.isEmpty || units <= 0) return;

                  Navigator.pop(ctx);
                  await context.read<PlanningProvider>().addInvestment(
                        name: name,
                        type: type,
                        units: units,
                        avgBuyPrice: buyPrice,
                        currentPrice: curPrice,
                      );
                  if (context.mounted) {
                    context.read<DashboardProvider>().fetchSummary();
                  }
                },
                child: const Text('Simpan Aset'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUpdatePrice(BuildContext context, Investment inv) {
    final priceController = TextEditingController(text: inv.currentPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Perbarui Harga ${inv.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Harga beli rata-rata: ${FormatService.rupiah(inv.avgBuyPrice)}'),
            const SizedBox(height: 14),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Harga Pasar Terbaru (Rp)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
              if (newPrice == null) return;

              Navigator.pop(ctx);
              await context.read<PlanningProvider>().updateInvestmentPrice(inv.id, newPrice);
              if (context.mounted) {
                context.read<DashboardProvider>().fetchSummary();
              }
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planning = context.watch<PlanningProvider>();
    final isGain = planning.totalGainLoss >= 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddInvestment(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Aset Baru', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () => planning.fetchInvestments(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Portfolio summary card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Nilai Portofolio', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    FormatService.rupiah(planning.totalInvestmentValue),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isGain ? '+' : ''}${FormatService.rupiah(planning.totalGainLoss)} (${planning.gainLossPercentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: isGain ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Unrealized Gain/Loss', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (planning.investments.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.trending_up, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('Belum ada portofolio investasi', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Catat saham, reksadana, emas, atau kripto untuk memantau net worth.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              )
            else
              ...planning.investments.map((inv) => _buildInvestmentCard(context, inv)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, Investment inv) {
    final isGain = inv.unrealizedGainLoss >= 0;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${inv.typeLabel} • ${inv.units} unit', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                  tooltip: 'Update Harga',
                  onPressed: () => _openUpdatePrice(context, inv),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nilai Pasar Terkini', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(FormatService.rupiah(inv.currentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Untung / Rugi', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      '${isGain ? '+' : ''}${FormatService.rupiah(inv.unrealizedGainLoss)} (${inv.unrealizedGainLossPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isGain ? const Color(0xFF059669) : const Color(0xFFDC2626),
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

