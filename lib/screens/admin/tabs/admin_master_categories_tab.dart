import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../models/category.dart';
import '../../../providers/admin_provider.dart';

class AdminMasterCategoriesTab extends StatefulWidget {
  const AdminMasterCategoriesTab({super.key});

  @override
  State<AdminMasterCategoriesTab> createState() => _AdminMasterCategoriesTabState();
}

class _AdminMasterCategoriesTabState extends State<AdminMasterCategoriesTab> {
  String _typeFilter = 'all'; // all, expense, income
  String _scopeFilter = 'all'; // all, master, custom
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<AdminProvider>().fetchMasterCategories(
      type: _typeFilter,
      scope: _scopeFilter,
      search: _searchCtrl.text.trim(),
    );
  }

  void _openAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    String typeVal = 'expense';
    String colorVal = '#3B82F6';
    final availableColors = [
      '#EF4444', '#F97316', '#F59E0B', '#10B981', '#14B8A6',
      '#3B82F6', '#6366F1', '#8B5CF6', '#EC4899', '#64748B'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Tambah Kategori Master', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori master dapat langsung digunakan oleh seluruh pengguna aplikasi PlanIt.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori (misal: Tagihan, Pajak, Hiburan)',
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Tipe Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: typeVal,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => typeVal = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Pilih Warna Label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableColors.map((hex) {
                    final isSelected = colorVal == hex;
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () => setDialogState(() => colorVal = hex),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                final success = await context.read<AdminProvider>().createMasterCategory(
                  name: name,
                  type: typeVal,
                  color: colorVal,
                );

                if (success && mounted) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori master "$name" berhasil dibuat!'),
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

  void _confirmPromoteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Jadikan Kategori Master?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(
          'Kategori "${cat.name}" yang dibuat oleh ${cat.userName ?? 'pengguna'} akan diubah menjadi Kategori Master Sistem. Kategori ini akan tersedia untuk seluruh pengguna aplikasi PlanIt.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().promoteCategoryToMaster(cat.id);
              if (success && mounted) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kategori "${cat.name}" berhasil dijadikan Kategori Master!'),
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                );
              }
            },
            child: const Text('Ya, Jadikan Master', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(Category cat) {
    final isMaster = cat.isMaster;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isMaster ? 'Hapus Kategori Master?' : 'Hapus Kategori Pengguna?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${cat.name}"? Kategori tidak akan muncul lagi di formulir transaksi.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().deleteMasterCategory(cat.id);
              if (success && mounted) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kategori "${cat.name}" berhasil dihapus'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = admin.masterCategories.where((c) {
      if (_typeFilter != 'all' && c.type != _typeFilter) return false;
      if (_scopeFilter == 'master' && !c.isMaster) return false;
      if (_scopeFilter == 'custom' && c.isMaster) return false;
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCategoryDialog,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kategori Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama kategori atau pembuat...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadData();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
                const SizedBox(height: 10),

                // Scope Filters (Master vs Custom User)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildScopeChip('Semua (${admin.masterCount + admin.customCount})', 'all'),
                      const SizedBox(width: 8),
                      _buildScopeChip('👑 Master Sistem (${admin.masterCount})', 'master'),
                      const SizedBox(width: 8),
                      _buildScopeChip('👤 Kustom Pengguna (${admin.customCount})', 'custom'),
                      const SizedBox(width: 16),
                      Container(height: 20, width: 1, color: Theme.of(context).dividerColor),
                      const SizedBox(width: 16),
                      _buildTypeChip('Semua Tipe', 'all'),
                      const SizedBox(width: 8),
                      _buildTypeChip('Pengeluaran', 'expense'),
                      const SizedBox(width: 8),
                      _buildTypeChip('Pemasukan', 'income'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Categories List
          Expanded(
            child: admin.isLoading && admin.masterCategories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Tidak ada kategori ditemukan', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isIncome = cat.type == 'income';
                            final isMaster = cat.isMaster;
                            final color = Color(int.parse((cat.color ?? '#3B82F6').replaceFirst('#', '0xFF')));

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Icon(Icons.category, color: color, size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMaster
                                            ? (isDark ? Colors.purple.shade900.withOpacity(0.4) : Colors.purple.shade50)
                                            : (isDark ? Colors.blue.shade900.withOpacity(0.4) : Colors.blue.shade50),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isMaster ? 'MASTER' : 'KUSTOM USER',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isMaster
                                              ? (isDark ? Colors.purple.shade200 : const Color(0xFF6D28D9))
                                              : (isDark ? Colors.blue.shade200 : const Color(0xFF1D4ED8)),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      isIncome ? 'Kategori Pemasukan' : 'Kategori Pengeluaran',
                                      style: TextStyle(fontSize: 11, color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor),
                                    ),
                                    if (!isMaster)
                                      Text(
                                        'Dibuat oleh: ${cat.userName ?? 'Pengguna'} (${cat.userEmail ?? '-'})',
                                        style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isMaster)
                                      IconButton(
                                        icon: const Icon(Icons.star_border_rounded, color: Color(0xFF8B5CF6), size: 22),
                                        tooltip: 'Jadikan Kategori Master untuk semua pengguna',
                                        onPressed: () => _confirmPromoteCategory(cat),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      tooltip: 'Hapus Kategori',
                                      onPressed: () => _confirmDeleteCategory(cat),
                                    ),
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

  Widget _buildScopeChip(String label, String scope) {
    final isSelected = _scopeFilter == scope;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF8B5CF6);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _scopeFilter = scope);
        _loadData();
      },
      selectedColor: accent.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? accent : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
      side: BorderSide(color: isSelected ? accent : Theme.of(context).dividerColor),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _typeFilter == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _typeFilter = type);
        _loadData();
      },
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
