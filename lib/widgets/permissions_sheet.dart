import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/shortcut_service.dart';

class PermissionsSheet extends StatefulWidget {
  const PermissionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const PermissionsSheet(),
    );
  }

  @override
  State<PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<PermissionsSheet> {
  Map<String, dynamic> _states = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await ShortcutService.instance.getFeatureStates();
    if (!mounted) return;
    setState(() {
      _states = s;
      _loading = false;
    });
  }

  void _copyAdbCommand() {
    Clipboard.setData(const ClipboardData(
      text:
          'adb shell pm grant com.example.shortcut_tools android.permission.WRITE_SECURE_SETTINGS',
    ));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perintah ADB disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool hasSecure = _states['hasWriteSecureSettings'] == true;
    final bool canWrite = _states['canWriteSettings'] == true;
    final bool canDnd = _states['canAccessNotificationPolicy'] == true;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.admin_panel_settings,
                      color: colorScheme.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perizinan Sistem & Super-Powers',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Aktifkan kontrol penuh toggle instan di dalam app',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Segarkan',
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.teal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aplikasi ini dapat langsung mengaktifkan/mematikan fitur sistem tanpa membuka menu Pengaturan jika izin berikut diberikan.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. WRITE_SECURE_SETTINGS (ADB)
                _PermissionCard(
                  icon: Icons.security,
                  title: 'WRITE_SECURE_SETTINGS (Akses ADB / Shizuku)',
                  description:
                      'Mengaktifkan toggle otomatis instan untuk DNS Pribadi, Penghemat Baterai, Wi-Fi, dan Lokasi.',
                  isGranted: hasSecure,
                  actionWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const SelectableText(
                          'adb shell pm grant com.example.shortcut_tools android.permission.WRITE_SECURE_SETTINGS',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Salin Perintah ADB'),
                        onPressed: _copyAdbCommand,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. WRITE_SETTINGS (System Settings)
                _PermissionCard(
                  icon: Icons.tune,
                  title: 'Ubah Pengaturan Sistem (WRITE_SETTINGS)',
                  description:
                      'Mengizinkan toggle Rotasi Otomatis & Kecerahan Layar langsung dari tombol ikon.',
                  isGranted: canWrite,
                  actionWidget: FilledButton.tonalIcon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Buka Halaman Izin'),
                    onPressed: () async {
                      await ShortcutService.instance.requestPermission('write_settings');
                      Future.delayed(const Duration(seconds: 1), _load);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Notification Policy Access (DND / Jangan Ganggu)
                _PermissionCard(
                  icon: Icons.notifications_off,
                  title: 'Akses Jangan Ganggu (DND / Sound)',
                  description:
                      'Mengizinkan toggle Mode Hening (Silent Mode) tanpa batasan sistem Android.',
                  isGranted: canDnd,
                  actionWidget: FilledButton.tonalIcon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Buka Izin DND'),
                    onPressed: () async {
                      await ShortcutService.instance.requestPermission('notification_policy');
                      Future.delayed(const Duration(seconds: 1), _load);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final Widget? actionWidget;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isGranted ? Colors.teal : colorScheme.outlineVariant,
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isGranted ? Colors.teal : colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isGranted ? 'DIIZINKAN' : 'BELUM AKTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            if (!isGranted && actionWidget != null) ...[
              const SizedBox(height: 10),
              actionWidget!,
            ],
          ],
        ),
      ),
    );
  }
}
