import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/shortcuts_catalog.dart';
import '../models/tool_shortcut.dart';
import '../services/favorites_service.dart';
import '../services/onboarding_service.dart';
import '../services/recents_service.dart';
import '../services/shortcut_service.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String _category = 'Semua';
  String? _tileId;
  List<String> _favIds = [];
  List<String> _recentIds = [];

  @override
  void initState() {
    super.initState();
    _handlePinnedLaunch();
    _loadTileId();
    _loadFavs();
    _loadRecents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOnboarding());
  }

  /// Tampilkan petunjuk gestur sekali saja di peluncuran pertama.
  Future<void> _maybeOnboarding() async {
    if (!await OnboardingService.instance.shouldShow()) return;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang di Shortcut Tools',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _OnboardRow(
                icon: Icons.touch_app,
                text: 'Ketuk kartu untuk langsung membuka halaman pengaturannya.',
              ),
              const SizedBox(height: 8),
              const _OnboardRow(
                icon: Icons.touch_app_outlined,
                text: 'Tahan kartu untuk menu: favorit, pin ke Home Screen, Quick Tile.',
              ),
              const SizedBox(height: 8),
              const _OnboardRow(
                icon: Icons.star_border,
                text: 'Yang sering dipakai otomatis naik ke "Terakhir dibuka".',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await OnboardingService.instance.markSeen();
  }

  /// Kalau aplikasi dibuka lewat pinned shortcut di home screen,
  /// langsung buka halaman Settings-nya tanpa menunggu tap.
  Future<void> _handlePinnedLaunch() async {
    final m = await ShortcutService.instance.consumePinnedShortcut();
    if (m == null) return;
    final ok = await ShortcutService.instance.openRaw(
      action: m['action'] as String? ?? '',
      fallbacks: List<String>.from(m['fallbacks'] as List? ?? const []),
      dataUri: m['dataUri'] as String?,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka halaman pengaturan')),
      );
    }
  }

  Future<void> _loadTileId() async {
    final id = await ShortcutService.instance.getTileShortcutId();
    if (mounted) setState(() => _tileId = id);
  }

  Future<void> _loadFavs() async {
    final ids = await FavoritesService.instance.getFavorites();
    if (mounted) setState(() => _favIds = ids);
  }

  Future<void> _loadRecents() async {
    final ids = await RecentsService.instance.getRecents();
    if (mounted) setState(() => _recentIds = ids);
  }

  List<ToolShortcut> _orderedByIds(List<String> ids) {
    final byId = {for (final s in kShortcuts) s.id: s};
    return [for (final id in ids) if (byId.containsKey(id)) byId[id]!];
  }

  /// Favorit sesuai urutan user menandainya.
  List<ToolShortcut> get _favorites => _orderedByIds(_favIds);

  /// Terakhir dibuka, paling baru di depan.
  List<ToolShortcut> get _recents => _orderedByIds(_recentIds);

  List<ToolShortcut> get _filtered {
    return kShortcuts.where((s) {
      final matchCat = _category == 'Semua' || s.category == _category;
      final q = _query.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.keywords.any((k) => k.toLowerCase().contains(q));
      return matchCat && matchQuery;
    }).toList();
  }

  Future<void> _open(ToolShortcut s) async {
    final ok = await ShortcutService.instance.open(s);
    if (ok) {
      await RecentsService.instance.recordOpen(s.id);
      await _loadRecents();
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka "${s.title}" di perangkat ini')),
      );
    }
  }

  Future<void> _pin(ToolShortcut s) async {
    final ok = await ShortcutService.instance.pinToHomeScreen(s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Ikuti dialog sistem untuk pin "${s.title}" ke Home Screen'
            : 'Perangkat/launcher ini tidak mendukung pin shortcut'),
      ),
    );
  }

  Future<void> _setTile(ToolShortcut s) async {
    await ShortcutService.instance.setAsTileShortcut(s);
    if (!mounted) return;
    setState(() => _tileId = s.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '"${s.title}" dipasang sebagai Quick Tile — tambahkan lewat Edit tiles di notification shade'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Menu aksi tambahan, muncul saat kartu ditahan (long-press).
  void _showActions(ToolShortcut s) {
    final isFav = _favIds.contains(s.id);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text('Buka "${s.title}"'),
              onTap: () {
                Navigator.pop(context);
                _open(s);
              },
            ),
            ListTile(
              leading: Icon(isFav ? Icons.star : Icons.star_border),
              title: Text(isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
              onTap: () async {
                Navigator.pop(context);
                final nowFav =
                    await FavoritesService.instance.toggleFavorite(s);
                await _loadFavs();
                await ShortcutService.instance.refreshWidgets();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(nowFav
                        ? '"${s.title}" ditambah ke Favorit'
                        : '"${s.title}" dihapus dari Favorit'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Pin ke Home Screen'),
              onTap: () {
                Navigator.pop(context);
                _pin(s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.widgets),
              title: const Text('Jadikan Quick Tile'),
              onTap: () {
                Navigator.pop(context);
                _setTile(s);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Pilih tema: Terang / Gelap / Ikuti sistem.
  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: ThemeService.instance,
          builder: (context, child) {
            final current = ThemeService.instance.mode;
            Widget item(ThemeMode mode, IconData icon, String label) {
              return ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: current == mode
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ThemeService.instance.setMode(mode);
                  Navigator.pop(ctx);
                },
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                item(ThemeMode.light, Icons.light_mode, 'Terang'),
                item(ThemeMode.dark, Icons.dark_mode, 'Gelap'),
                item(ThemeMode.system, Icons.settings_suggest, 'Ikuti sistem'),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['Semua', ...kCategories];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shortcut Tools'),
        actions: [
          ListenableBuilder(
            listenable: ThemeService.instance,
            builder: (context, _) => IconButton(
              tooltip: 'Tema (${ThemeService.instance.label})',
              icon: Icon(switch (ThemeService.instance.mode) {
                ThemeMode.light => Icons.light_mode,
                ThemeMode.dark => Icons.dark_mode,
                ThemeMode.system => Icons.settings_suggest,
              }),
              onPressed: _showThemePicker,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari pengaturan… (mis. dns)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(cats[i]),
                selected: _category == cats[i],
                onSelected: (_) => setState(() => _category = cats[i]),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_recents.isNotEmpty) ...[
                  _StripHeader(
                    icon: Icons.history,
                    title: 'Terakhir dibuka',
                    actionLabel: 'Hapus',
                    onAction: () async {
                      await RecentsService.instance.clear();
                      await _loadRecents();
                    },
                  ),
                  _cardStrip(_recents),
                  const Divider(height: 1),
                ],
                if (_favorites.isNotEmpty) ...[
                  const _StripHeader(icon: Icons.star, title: 'Favorit'),
                  _cardStrip(_favorites),
                  const Divider(height: 1),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Semua',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Tidak ada hasil.')),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _ToolCard(
                      shortcut: _filtered[i],
                      isTile: _tileId == _filtered[i].id,
                      isFav: _favIds.contains(_filtered[i].id),
                      onTap: () => _open(_filtered[i]),
                      onLongPress: () => _showActions(_filtered[i]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Strip horizontal kartu untuk Terakhir dibuka / Favorit.
  Widget _cardStrip(List<ToolShortcut> items) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(
          width: 124,
          child: _ToolCard(
            shortcut: items[i],
            isTile: _tileId == items[i].id,
            isFav: _favIds.contains(items[i].id),
            onTap: () => _open(items[i]),
            onLongPress: () => _showActions(items[i]),
          ),
        ),
      ),
    );
  }
}

class _StripHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StripHeader({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Kartu tool: ikon + judul + deskripsi singkat.
/// Tap = buka langsung, tahan = menu aksi.
class _ToolCard extends StatelessWidget {
  final ToolShortcut shortcut;
  final bool isTile;
  final bool isFav;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ToolCard({
    required this.shortcut,
    required this.onTap,
    required this.onLongPress,
    this.isTile = false,
    this.isFav = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    shortcut.icon,
                    size: 24,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                if (isFav)
                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                if (isTile) ...[
                  if (isFav) const SizedBox(width: 4),
                  Icon(Icons.widgets, size: 16, color: scheme.primary),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              shortcut.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                shortcut.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (shortcut.globalKey != null)
              _LiveDot(keyName: shortcut.globalKey!),
          ],
        ),
      ),
    );
  }
}

/// Titik status live dari Settings.Global (tanpa permission).
/// Hijau = aktif/terisi, abu = mati/kosong.
class _LiveDot extends StatelessWidget {
  final String keyName;
  const _LiveDot({required this.keyName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ShortcutService.instance.getGlobalSetting(keyName),
      builder: (context, snap) {
        final raw = snap.data;
        final active = raw != null && raw != 'off' && raw.isNotEmpty;
        final label = ShortcutService.prettyPrivateDnsMode(raw);
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Satu baris petunjuk di onboarding.
class _OnboardRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OnboardRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
