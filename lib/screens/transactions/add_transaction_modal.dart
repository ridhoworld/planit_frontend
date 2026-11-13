import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  String _type = 'expense'; // expense, income, transfer
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  int? _selectedAccountId;
  int? _selectedTargetAccountId;
  int? _selectedCategoryId;
  final List<int> _selectedTagIds = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accProvider = context.read<AccountProvider>();
      final txProvider = context.read<TransactionProvider>();

      if (accProvider.activeAccounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = accProvider.activeAccounts.first.id;
          if (accProvider.activeAccounts.length > 1) {
            _selectedTargetAccountId = accProvider.activeAccounts[1].id;
          }
        });
      }

      final defaultCats = _type == 'expense' ? txProvider.expenseCategories : txProvider.incomeCategories;
      if (defaultCats.isNotEmpty) {
        setState(() {
          _selectedCategoryId = defaultCats.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addAmount(double add) {
    double current = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    current += add;
    setState(() {
      _amountController.text = current.toStringAsFixed(0);
    });
  }

  void _submit() async {
    final amountVal = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal transaksi yang valid')),
      );
      return;
    }

    final accProvider = context.read<AccountProvider>();
    final accounts = accProvider.activeAccounts;

    final validSourceId = accounts.any((a) => a.id == _selectedAccountId)
        ? _selectedAccountId
        : (accounts.isNotEmpty ? accounts.first.id : null);

    if (validSourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun / dompet sumber')),
      );
      return;
    }

    int? validTargetId;
    int? validCategoryId;

    if (_type == 'transfer') {
      if (accounts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimal harus ada 2 akun aktif untuk melakukan transfer')),
        );
        return;
      }

      final availableTargets = accounts.where((a) => a.id != validSourceId).toList();
      validTargetId = availableTargets.any((a) => a.id == _selectedTargetAccountId)
          ? _selectedTargetAccountId
          : (availableTargets.isNotEmpty ? availableTargets.first.id : null);

      if (validTargetId == null || validTargetId == validSourceId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih akun tujuan yang berbeda')),
        );
        return;
      }
    } else {
      final txProvider = context.read<TransactionProvider>();
      final categories = _type == 'expense' ? txProvider.expenseCategories : txProvider.incomeCategories;
      validCategoryId = categories.any((c) => c.id == _selectedCategoryId)
          ? _selectedCategoryId
          : (categories.isNotEmpty ? categories.first.id : null);

      if (validCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori transaksi')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final txProvider = context.read<TransactionProvider>();
    final success = await txProvider.addTransaction(
      accountId: validSourceId,
      targetAccountId: _type == 'transfer' ? validTargetId : null,
      categoryId: _type != 'transfer' ? validCategoryId : null,
      type: _type,
      amount: amountVal,
      transactionDate: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Refresh dashboard & accounts
      context.read<DashboardProvider>().fetchSummary();
      context.read<AccountProvider>().fetchAccounts();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
          backgroundColor: AppTheme.incomeColor,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txProvider.errorMessage ?? 'Gagal menyimpan transaksi'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _openAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedColor = '#3B82F6';
    final availableColors = [
      '#EF4444', '#F97316', '#F59E0B', '#10B981', '#14B8A6',
      '#3B82F6', '#6366F1', '#8B5CF6', '#EC4899', '#64748B'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Tambah Kategori ${_type == 'expense' ? 'Pengeluaran' : 'Pemasukan'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori (mis. Kopi, Skincare, Kos)',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pilih Warna Label', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableColors.map((hex) {
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final isSelected = selectedColor == hex;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = hex),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black87, width: 2.5) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                final newCat = await context.read<TransactionProvider>().addCategory(
                  name: name,
                  type: _type == 'expense' ? 'expense' : 'income',
                  color: selectedColor,
                );

                if (newCat != null && mounted) {
                  setState(() {
                    _selectedCategoryId = newCat.id;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori "${newCat.name}" berhasil dibuat!'),
                      backgroundColor: AppTheme.incomeColor,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAndScanReceipt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pindai Struk / Bukti Pembayaran AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'AI akan membaca foto struk belanja atau screenshot m-Banking/QRIS untuk mengisi nominal & kategori otomatis.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                ),
                title: const Text('Ambil Foto Struk (Kamera)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Foto langsung struk kasir atau struk ATM', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.purple),
                ),
                title: const Text('Pilih dari Galeri / Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Screenshot bukti m-Banking / GoPay / QRIS', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Memindai Dokumen...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('AI sedang mengekstrak struk transaksi...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final result = await context.read<AiProvider>().scanReceipt(image);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (result != null && mounted) {
        setState(() {
          final amt = result['amount'];
          if (amt != null) {
            _amountController.text = amt.toString().replaceAll('.0', '');
          }
          if (result['type'] != null && (result['type'] == 'expense' || result['type'] == 'income')) {
            _type = result['type'];
          }
          if (result['suggested_category_id'] != null) {
            _selectedCategoryId = int.tryParse(result['suggested_category_id'].toString()) ?? _selectedCategoryId;
          }
          final merchant = result['merchant'] ?? '';
          final notes = result['notes'] ?? '';
          _notesController.text = "$merchant $notes".trim();

          if (result['date'] != null) {
            _selectedDate = DateTime.tryParse(result['date']) ?? _selectedDate;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Berhasil memindai struk: ${result['merchant'] ?? 'Transaksi'}!'),
            backgroundColor: AppTheme.incomeColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindai: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accProvider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accounts = accProvider.activeAccounts;
    final categories = _type == 'expense' ? txProvider.expenseCategories : txProvider.incomeCategories;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // AI Scan Receipt Button
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: _pickAndScanReceipt,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F766E).withOpacity(0.4), const Color(0xFF1E3A8A).withOpacity(0.4)]
                          : [const Color(0xFFCCFBF1), const Color(0xFFDBEAFE)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF14B8A6).withOpacity(0.4) : const Color(0xFF5EEAD4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pindai Struk / Bukti Transfer AI',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Ekstrak nominal, toko, & kategori otomatis',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // Segmented Type Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildTypeTab('expense', 'Pengeluaran', AppTheme.expenseColor),
                  _buildTypeTab('income', 'Pemasukan', AppTheme.incomeColor),
                  _buildTypeTab('transfer', 'Transfer', AppTheme.accentColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Input Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nominal (Rp)', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Quick Nominal Chips (< 10 seconds entry)
            Row(
              children: [
                _buildQuickChip('+ 10.000', 10000),
                const SizedBox(width: 8),
                _buildQuickChip('+ 50.000', 50000),
                const SizedBox(width: 8),
                _buildQuickChip('+ 100.000', 100000),
                const SizedBox(width: 8),
                _buildQuickChip('+ 500.000', 500000),
              ],
            ),
            const SizedBox(height: 18),

            // Source Account Selector
            Text('Sumber Dana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: accounts.any((a) => a.id == _selectedAccountId)
                  ? _selectedAccountId
                  : (accounts.isNotEmpty ? accounts.first.id : null),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
              ),
              items: accounts.map((a) {
                return DropdownMenuItem<int>(
                  value: a.id,
                  child: Text('${a.name} (Rp ${NumberFormat('#,###', 'id_ID').format(a.currentBalance)})'),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedAccountId = val;
                  final remaining = accounts.where((a) => a.id != val).toList();
                  if (_selectedTargetAccountId == val || !remaining.any((a) => a.id == _selectedTargetAccountId)) {
                    _selectedTargetAccountId = remaining.isNotEmpty ? remaining.first.id : null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),

            // Target Account Selector (Transfer only)
            if (_type == 'transfer') ...[
              Text('Akun Tujuan Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final activeSourceId = accounts.any((a) => a.id == _selectedAccountId)
                      ? _selectedAccountId
                      : (accounts.isNotEmpty ? accounts.first.id : null);
                  final availableTargets = accounts.where((a) => a.id != activeSourceId).toList();
                  final safeTargetValue = availableTargets.any((a) => a.id == _selectedTargetAccountId)
                      ? _selectedTargetAccountId
                      : (availableTargets.isNotEmpty ? availableTargets.first.id : null);

                  if (availableTargets.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Perlu minimal 2 akun/dompet aktif untuk transfer.',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    value: safeTargetValue,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: Icon(Icons.arrow_forward_rounded, size: 20),
                    ),
                    items: availableTargets.map((a) {
                      return DropdownMenuItem<int>(
                        value: a.id,
                        child: Text('${a.name} (Rp ${NumberFormat('#,###', 'id_ID').format(a.currentBalance)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTargetAccountId = val),
                  );
                },
              ),
              const SizedBox(height: 14),
            ],

            // Category Selector (Income & Expense)
            if (_type != 'transfer') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                  InkWell(
                    onTap: _openAddCategoryDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        '+ Kategori Baru',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse((c.color ?? '#3B82F6').replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 14),
            ],

            // Date & Notes Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Catatan (opsional)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan Transaksi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, Color color) {
    final isSelected = _type == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            final accProvider = context.read<AccountProvider>();
            final accounts = accProvider.activeAccounts;

            if (type == 'transfer') {
              final activeSourceId = accounts.any((a) => a.id == _selectedAccountId)
                  ? _selectedAccountId
                  : (accounts.isNotEmpty ? accounts.first.id : null);
              final available = accounts.where((a) => a.id != activeSourceId).toList();
              if (_selectedTargetAccountId == null ||
                  _selectedTargetAccountId == activeSourceId ||
                  !available.any((a) => a.id == _selectedTargetAccountId)) {
                _selectedTargetAccountId = available.isNotEmpty ? available.first.id : null;
              }
            } else {
              final txProvider = context.read<TransactionProvider>();
              final list = type == 'expense' ? txProvider.expenseCategories : txProvider.incomeCategories;
              if (list.isNotEmpty && (_selectedCategoryId == null || !list.any((c) => c.id == _selectedCategoryId))) {
                _selectedCategoryId = list.first.id;
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double add) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _addAmount(add),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
