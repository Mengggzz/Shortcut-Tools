import 'package:flutter/material.dart';
import '../models/tool_shortcut.dart';
import '../services/shortcut_service.dart';

class ToolDetailSheet extends StatefulWidget {
  final ToolShortcut shortcut;
  final VoidCallback onOpenNativeSettings;

  const ToolDetailSheet({
    super.key,
    required this.shortcut,
    required this.onOpenNativeSettings,
  });

  static Future<void> show(
    BuildContext context, {
    required ToolShortcut shortcut,
    required VoidCallback onOpenNativeSettings,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ToolDetailSheet(
        shortcut: shortcut,
        onOpenNativeSettings: onOpenNativeSettings,
      ),
    );
  }

  @override
  State<ToolDetailSheet> createState() => _ToolDetailSheetState();
}

class _ToolDetailSheetState extends State<ToolDetailSheet> {
  Map<String, dynamic> _systemInfo = {};
  int? _pingResult;
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final info = await ShortcutService.instance.getSystemInfo();
    if (!mounted) return;
    setState(() {
      _systemInfo = info;
    });
  }

  Future<void> _runPing() async {
    setState(() => _isPinging = true);
    final res = await ShortcutService.instance.pingHost('1.1.1.1');
    if (!mounted) return;
    setState(() {
      _isPinging = false;
      _pingResult = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = widget.shortcut;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                  child: Icon(s.icon, color: colorScheme.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        s.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
                // Deskripsi
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fungsi & Kegunaan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(s.description, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // In-App Interactive Widgets per Feature
                if (s.id == 'wifi' || s.id == 'vpn') ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.network_check, size: 18),
                              SizedBox(width: 8),
                              Text('Uji Koneksi & Latensi Jaringan',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _pingResult != null
                                      ? (_pingResult! > 0
                                          ? 'Latensi Ping: ${_pingResult}ms'
                                          : 'Gagal / Tidak Terhubung')
                                      : 'Uji respons koneksi ke gateway internet.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _pingResult != null
                                        ? (_pingResult! > 0 ? Colors.green : Colors.red)
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: _pingResult != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: _isPinging ? null : _runPing,
                                child: _isPinging
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Tes Sekarang'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (s.id == 'battery_saver') ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            _systemInfo['isCharging'] == true
                                ? Icons.battery_charging_full
                                : Icons.battery_std,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level Baterai: ${_systemInfo['batteryPercent'] ?? 0}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _systemInfo['isCharging'] == true
                                      ? 'Sedang mengisi daya'
                                      : 'Mode baterai aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (s.id == 'device_info') ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Perangkat Ini',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _infoRow('Merek / Brand', '${_systemInfo['brand'] ?? _systemInfo['manufacturer'] ?? "—"}'),
                          _infoRow('Model Perangkat', '${_systemInfo['model'] ?? "—"}'),
                          _infoRow('Versi Android', '${_systemInfo['androidVersion'] ?? "—"} (SDK ${_systemInfo['sdkInt'] ?? "—"})'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Intent Details Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Teknis Intent:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aksi Utama: ${s.action}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                      if (s.fallbacks.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Fallback (${s.fallbacks.length} jalur): ${s.fallbacks.first}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button Open Settings
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                      'Buka ${s.title} di Pengaturan HP',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onOpenNativeSettings();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
