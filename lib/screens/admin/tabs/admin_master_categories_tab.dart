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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchMasterCategories();
    });
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
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.swap_vert)),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Pengeluaran (Expense)')),
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan (Income)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => typeVal = v);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Warna Label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableColors.map((hex) {
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final isSelected = colorVal == hex;
                    return InkWell(
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);

                final adminProv = context.read<AdminProvider>();
                final success = await adminProv.createMasterCategory(
                  name: name,
                  type: typeVal,
                  color: colorVal,
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori master berhasil ditambahkan!'), backgroundColor: AppTheme.incomeColor),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(adminProv.errorMessage ?? 'Gagal menambahkan kategori'), backgroundColor: Colors.red.shade700),
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

  void _confirmDeleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori Master?'),
        content: Text('Apakah Anda yakin ingin menghapus kategori master "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final adminProv = context.read<AdminProvider>();
              final success = await adminProv.deleteMasterCategory(cat.id);

              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kategori ${cat.name} berhasil dihapus.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(adminProv.errorMessage ?? 'Gagal menghapus kategori'), backgroundColor: Colors.red.shade700),
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

    final categories = admin.masterCategories.where((c) {
      if (_typeFilter == 'all') return true;
      return c.type == _typeFilter;
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
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pengeluaran', 'expense'),
                const SizedBox(width: 8),
                _buildFilterChip('Pemasukan', 'income'),
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
                            const Text('Tidak ada kategori master', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => admin.fetchMasterCategories(type: _typeFilter),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isIncome = cat.type == 'income';
                            final color = Color(int.parse((cat.color ?? '#3B82F6').replaceFirst('#', '0xFF')));

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Icon(Icons.category, color: color, size: 20),
                                ),
                                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(
                                  isIncome ? 'Kategori Pemasukan Master' : 'Kategori Pengeluaran Master',
                                  style: TextStyle(fontSize: 11, color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDeleteCategory(cat),
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
    const accent = Color(0xFF8B5CF6);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _typeFilter = type),
      selectedColor: accent.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? accent : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
      side: BorderSide(color: isSelected ? accent : Theme.of(context).dividerColor),
    );
  }
}

