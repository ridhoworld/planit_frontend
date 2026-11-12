import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminUsersScreen({super.key, this.showAppBar = true});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'all'; // all, admin, user

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    context.read<AdminProvider>().fetchUsers(
      search: val,
      role: _selectedRoleFilter,
    );
  }

  void _onFilterChanged(String role) {
    setState(() => _selectedRoleFilter = role);
    context.read<AdminProvider>().fetchUsers(
      search: _searchController.text,
      role: role,
    );
  }

  void _openAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String roleVal = 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: AppTheme.primaryColor),
              SizedBox(width: 10),
              Text('Tambah Pengguna Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Akun yang dibuat akan langsung dapat digunakan untuk masuk ke PlanIt.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Awal',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Minimal 6 karakter',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Kata sandi wajib diisi';
                      if (v.trim().length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Role / Peran Pengguna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: roleVal,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Pengguna Biasa (User)')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator (Admin)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => roleVal = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);

                final adminProv = context.read<AdminProvider>();
                final success = await adminProv.createUser(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: roleVal,
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengguna baru berhasil ditambahkan!'),
                      backgroundColor: AppTheme.incomeColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(adminProv.errorMessage ?? 'Gagal menambahkan pengguna'),
                      backgroundColor: Colors.red.shade700,
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

  void _openEditUserDialog(User user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final passCtrl = TextEditingController();
    String roleVal = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ubah Data Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Baru (Opsional)',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Biarkan kosong jika tidak ingin mengubah',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Role / Peran Pengguna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: roleVal,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Pengguna Biasa (User)')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator (Admin)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => roleVal = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);

                final adminProv = context.read<AdminProvider>();
                final success = await adminProv.updateUser(
                  id: user.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim().isEmpty ? null : passCtrl.text.trim(),
                  role: roleVal,
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data pengguna berhasil diperbarui!'),
                      backgroundColor: AppTheme.incomeColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(adminProv.errorMessage ?? 'Gagal memperbarui pengguna'),
                      backgroundColor: Colors.red.shade700,
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

  void _confirmDeleteUser(User user, int currentUserId) {
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menghapus akun Anda sendiri.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: Text('Apakah Anda yakin ingin menghapus akun "${user.name}" (${user.email})? Seluruh data pengguna ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final adminProv = context.read<AdminProvider>();
              final success = await adminProv.deleteUser(user.id);

              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pengguna ${user.name} berhasil dihapus.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(adminProv.errorMessage ?? 'Gagal menghapus pengguna'),
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
    final adminProv = context.watch<AdminProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manajemen Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Kelola akun & hak akses aplikasi', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddUserDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tambah Pengguna', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFilterChip('Semua', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Admin', 'admin'),
                    const SizedBox(width: 8),
                    _buildFilterChip('User Biasa', 'user'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User List
          Expanded(
            child: adminProv.isLoading && adminProv.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : adminProv.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada pengguna ditemukan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => adminProv.fetchUsers(
                          search: _searchController.text,
                          role: _selectedRoleFilter,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
                          itemCount: adminProv.users.length,
                          itemBuilder: (context, index) {
                            final user = adminProv.users[index];
                            final isMe = user.id == currentUserId;
                            final isAdmin = user.isAdmin;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 1,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isAdmin
                                      ? (isDark ? Colors.purple.shade900.withOpacity(0.5) : Colors.purple.shade100)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  child: Icon(
                                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                                    color: isAdmin
                                        ? (isDark ? Colors.purple.shade200 : Colors.purple.shade700)
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isMe)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.blue.shade900.withOpacity(0.4) : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                                        ),
                                        child: Text(
                                          'Anda',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.blue.shade200 : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(user.email, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? (isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isAdmin ? 'ADMINISTRATOR' : 'PENGGUNA BIASA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
                                              ? (isDark ? Colors.purple.shade200 : Colors.purple.shade700)
                                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _openEditUserDialog(user);
                                    } else if (val == 'delete') {
                                      _confirmDeleteUser(user, currentUserId);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Ubah Data / Password'),
                                        ],
                                      ),
                                    ),
                                    if (!isMe)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                            SizedBox(width: 8),
                                            Text('Hapus Pengguna', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
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

  Widget _buildFilterChip(String label, String role) {
    final isSelected = _selectedRoleFilter == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(role),
      selectedColor: primary.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
      side: BorderSide(
        color: isSelected ? primary : Theme.of(context).dividerColor,
      ),
    );
  }
}

