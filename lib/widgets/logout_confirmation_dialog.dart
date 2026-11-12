import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const LogoutConfirmationDialog(),
    );
  }

  @override
  State<LogoutConfirmationDialog> createState() => _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String _statusText = 'Mengamankan sesi Anda...';
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _executeLogout() async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Mengamankan data transaksi...';
    });

    final auth = context.read<AuthProvider>();
    final userName = auth.user?.name ?? 'Pengguna';

    // Tahap animasi 1: Simpan status
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _statusText = 'Menutup sesi aktif di server...';
    });

    // Tahap animasi 2: Salam perpisahan
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _statusText = 'Sampai jumpa lagi, $userName! 👋';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Tutup dialog lalu eksekusi logout
    Navigator.of(context, rootNavigator: true).pop();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.name ?? 'Pengguna';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: _isProcessing ? _buildProcessingView() : _buildConfirmationView(userName),
      ),
    );
  }

  // Tampilan 1: Dialog Konfirmasi Keluar
  Widget _buildConfirmationView(String userName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Badge dengan Efek Lembut
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? Colors.red.shade700 : Colors.red.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.logout_rounded,
            color: isDark ? Colors.red.shade300 : Colors.red.shade600,
            size: 34,
          ),
        ),
        const SizedBox(height: 20),

        // Judul & Pertanyaan
        Text(
          'Keluar dari Aplikasi?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Deskripsi Informatif
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4),
            children: [
              const TextSpan(text: 'Halo '),
              TextSpan(
                text: userName,
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF334155)),
              ),
              const TextSpan(
                text: ', sesi Anda akan diakhiri. Seluruh data keuangan Anda tersimpan dengan aman di server.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // Tombol Aksi (Batal & Keluar)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _executeLogout,
                icon: const Icon(Icons.exit_to_app_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Ya, Keluar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 2,
                  shadowColor: Colors.red.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tampilan 2: Animasi Proses Logout
  Widget _buildProcessingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        // Lingkaran Animasi Dinamis
        Stack(
          alignment: Alignment.center,
          children: [
            // Cincin Berputar (Rotating Ring)
            RotationTransition(
              turns: _rotationAnimation,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.0),
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor,
                    ],
                  ),
                ),
              ),
            ),
            // Cincin Dalam Sesuai Tema
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
            ),
            // Ikon Bernafas (Pulsing Icon)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Judul Status
        Text(
          'Sedang Menutup Sesi...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        // Pesan Dinamis dengan Animasi Pergantian Teks
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _statusText,
            key: ValueKey<String>(_statusText),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),

        // Loading bar ramping
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 140,
            height: 4,
            child: LinearProgressIndicator(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

