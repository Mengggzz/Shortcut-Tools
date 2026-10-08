import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tool_shortcut.dart';
import '../services/shortcut_service.dart';

class DnsPreset {
  final String id;
  final String name;
  final String hostname;
  final String description;
  final IconData icon;
  final Color color;

  const DnsPreset({
    required this.id,
    required this.name,
    required this.hostname,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<DnsPreset> kDnsPresets = [
  DnsPreset(
    id: 'controld_p2',
    name: 'Control D (Adblock & Tracking)',
    hostname: 'p2.freedns.controld.com',
    description: 'Blokir iklan, banner, pelacak, dan popup otomatis',
    icon: Icons.shield,
    color: Colors.deepPurple,
  ),
  DnsPreset(
    id: 'controld_family',
    name: 'Control D (Family Friendly)',
    hostname: 'family.freedns.controld.com',
    description: 'Blokir iklan + filter konten dewasa & malware',
    icon: Icons.family_restroom,
    color: Colors.indigo,
  ),
  DnsPreset(
    id: 'adguard_default',
    name: 'AdGuard DNS',
    hostname: 'dns.adguard-dns.com',
    description: 'Blokir iklan aplikasi, game, web & counter tracker',
    icon: Icons.verified_user,
    color: Colors.green,
  ),
  DnsPreset(
    id: 'adguard_family',
    name: 'AdGuard Family Protection',
    hostname: 'family.adguard-dns.com',
    description: 'Blokir iklan + filter situs berbahaya dan dewasa',
    icon: Icons.security,
    color: Colors.teal,
  ),
  DnsPreset(
    id: 'cloudflare_standard',
    name: 'Cloudflare (1.1.1.1)',
    hostname: 'one.one.one.one',
    description: 'DNS tercepat di dunia dengan privasi ketat TLS/DoT',
    icon: Icons.bolt,
    color: Colors.orange,
  ),
  DnsPreset(
    id: 'cloudflare_security',
    name: 'Cloudflare Security',
    hostname: 'security.cloudflare-dns.com',
    description: 'Perlindungan otomatis dari serangan malware & phishing',
    icon: Icons.lock,
    color: Colors.amber,
  ),
  DnsPreset(
    id: 'quad9',
    name: 'Quad9 Security DNS',
    hostname: 'dns.quad9.net',
    description: 'Proteksi cyber-threat intelligence dari IBM & Global Cyber Alliance',
    icon: Icons.shield_outlined,
    color: Colors.redAccent,
  ),
  DnsPreset(
    id: 'google',
    name: 'Google Public DNS',
    hostname: 'dns.google',
    description: 'DNS global stabil dengan latensi rendah dari Google',
    icon: Icons.public,
    color: Colors.blue,
  ),
];

class DnsManagerSheet extends StatefulWidget {
  final ToolShortcut shortcut;
  final VoidCallback onOpenNativeSettings;

  const DnsManagerSheet({
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
      builder: (_) => DnsManagerSheet(
        shortcut: shortcut,
        onOpenNativeSettings: onOpenNativeSettings,
      ),
    );
  }

  @override
  State<DnsManagerSheet> createState() => _DnsManagerSheetState();
}

class _DnsManagerSheetState extends State<DnsManagerSheet> {
  String _currentMode = '';
  String _currentSpecifier = '';
  bool _hasWriteSecure = false;
  bool _loading = true;
  String _selectedHostname = 'p2.freedns.controld.com';
  final TextEditingController _customController = TextEditingController();
  final Map<String, int> _pingResults = {};
  final Set<String> _pinging = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final info = await ShortcutService.instance.getSystemInfo();
    if (!mounted) return;
    setState(() {
      _currentMode = (info['privateDnsMode'] as String? ?? '').trim();
      _currentSpecifier = (info['privateDnsSpecifier'] as String? ?? '').trim();
      _hasWriteSecure = info['hasWriteSecureSettings'] == true;
      if (_currentSpecifier.isNotEmpty) {
        _selectedHostname = _currentSpecifier;
        _customController.text = _currentSpecifier;
      }
      _loading = false;
    });
  }

  Future<void> _testPing(String hostname) async {
    setState(() => _pinging.add(hostname));
    final latency = await ShortcutService.instance.pingHost(hostname);
    if (!mounted) return;
    setState(() {
      _pinging.remove(hostname);
      _pingResults[hostname] = latency;
    });
  }

  void _copyHostname(String hostname) {
    Clipboard.setData(ClipboardData(text: hostname));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hostname "$hostname" berhasil disalin!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _applyDirectly(String hostname) async {
    if (!_hasWriteSecure) {
      _showAdbGuideDialog(hostname);
      return;
    }

    final res = await ShortcutService.instance.setPrivateDns(
      mode: 'hostname',
      hostname: hostname,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DNS Pribadi berhasil diatur ke "$hostname" secara instan!'),
          backgroundColor: Colors.teal,
        ),
      );
      _loadStatus();
    } else {
      _showAdbGuideDialog(hostname);
    }
  }

  void _showAdbGuideDialog(String hostname) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Colors.teal),
            SizedBox(width: 10),
            Expanded(child: Text('Terapkan Otomatis (ADB)')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Android membatasi perubahan DNS langsung demi keamanan. Anda punya 2 pilihan mudah:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Cara Manual (1-Ketuk Salin & Buka Pengaturan):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Text(
                'Salin hostname lalu buka Pengaturan DNS dan paste.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text(
                '2. Aktifkan 1-Ketuk Langsung di Aplikasi via ADB (Sekali saja):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(
                text:
                    'adb shell pm grant com.example.shortcut_tools android.permission.WRITE_SECURE_SETTINGS',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perintah ADB disalin ke clipboard')),
              );
            },
            child: const Text('Salin Perintah ADB'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String modeLabel = switch (_currentMode) {
      'off' => 'Nonaktif / Mati',
      'opportunistic' => 'Otomatis',
      'hostname' => 'Kustom (${_currentSpecifier.isNotEmpty ? _currentSpecifier : "Aktif"})',
      _ => _currentMode.isNotEmpty ? _currentMode : 'Memuat...',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // App Bar Area
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
                  child: Icon(Icons.dns, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DNS Pribadi (Private DNS)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pilih & gunakan DNS terenkripsi DoT',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Segarkan status',
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _loading ? null : _loadStatus,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Live Status Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _currentMode == 'hostname'
                          ? Colors.teal
                          : colorScheme.outlineVariant,
                      width: _currentMode == 'hostname' ? 1.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _currentMode == 'hostname'
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _currentMode == 'hostname'
                                  ? Colors.teal
                                  : colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Status DNS di HP Saat Ini',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Mode: ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Text(
                                modeLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _currentMode == 'hostname'
                                      ? Colors.teal
                                      : colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_currentSpecifier.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Hostname Aktif: ', style: TextStyle(fontSize: 13)),
                              Expanded(
                                child: Text(
                                  _currentSpecifier,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: Colors.tealAccent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Heading
                Text(
                  'Pilihan Preset DNS Populer (Tinggal Pilih & Salin)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Preset List
                ...kDnsPresets.map((preset) {
                  final isSelected = _selectedHostname == preset.hostname;
                  final ping = _pingResults[preset.hostname];
                  final isPinging = _pinging.contains(preset.hostname);

                  return Card(
                    elevation: isSelected ? 2 : 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: preset.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(preset.icon, color: preset.color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      preset.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      preset.description,
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
                          const SizedBox(height: 10),
                          // Hostname container
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SelectableText(
                                    preset.hostname,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isPinging)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (ping != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ping > 0 && ping < 100
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : (ping > 0
                                              ? Colors.orange.withValues(alpha: 0.2)
                                              : Colors.red.withValues(alpha: 0.2)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ping > 0 ? '${ping}ms' : 'Gagal',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ping > 0 && ping < 100
                                            ? Colors.green
                                            : (ping > 0 ? Colors.orange : Colors.red),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Action buttons
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.speed, size: 16),
                                  label: const Text('Tes Ping', style: TextStyle(fontSize: 12)),
                                  onPressed: isPinging
                                      ? null
                                      : () => _testPing(preset.hostname),
                                ),
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Salin', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    setState(() => _selectedHostname = preset.hostname);
                                    _copyHostname(preset.hostname);
                                  },
                                ),
                                const SizedBox(width: 4),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.flash_on, size: 16),
                                  label: const Text('Terapkan', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    setState(() => _selectedHostname = preset.hostname);
                                    _applyDirectly(preset.hostname);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                // Custom Hostname
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Gunakan Hostname Kustom Lainnya',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            hintText: 'contoh: dns.domain-anda.com',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                if (_customController.text.trim().isNotEmpty) {
                                  _copyHostname(_customController.text.trim());
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Panduan Langkah
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Cara Memasang di HP Infinix / Android:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Klik tombol "Salin Hostname" pada DNS pilihan di atas.\n'
                        '2. Klik tombol "Buka Pengaturan DNS di HP" di bawah.\n'
                        '3. Pada halaman Pengaturan, pilih "DNS Pribadi" / "Private DNS".\n'
                        '4. Pilih "Hostname penyedia DNS pribadi", tempel/paste hostname, lalu Simpan.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Main Button: Open Settings
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.settings_suggest),
                    label: const Text(
                      'Buka Pengaturan DNS di HP',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
}
