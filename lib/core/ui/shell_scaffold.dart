import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
// import '../vocab/vocab_repo.dart';
// current_property and properties_screen now handled via Line2PropertyChip and picker
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/map/map_view.dart';
import '../services/gps_service.dart';
import '../../modules/shell/line2_property_chip.dart';
import '../../modules/shared/bottom_plus_menu.dart';
import '../../modules/shared/add_point_method_sheet.dart';
import '../../modules/util/icon_preview_screen.dart';
import '../../app_state/active_property.dart';
import '../../modules/points/add_point_gps_sheet.dart';
import '../../modules/points/add_point_tap_mode.dart';
import '../../modules/log/add_log_screen.dart';
import '../../modules/diary/add_diary_task_screen.dart';

import 'dev_seed_button.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({super.key});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final gpsAsync = ref.watch(gpsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72, // allow space for app name + tagline
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.appName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              t.tagline,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt),
            tooltip: t.global_filter,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            tooltip: t.global_search,
          ),
          PopupMenuButton<String>(
            tooltip: t.menu_top,
            onSelected: (v) => openTopMenu(context, v),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'props', child: Text(t.menu_properties)),
              PopupMenuItem(value: 'groups', child: Text(t.menu_groups)),
              const PopupMenuItem(value: 'params', child: Text('Parameters')),
              PopupMenuItem(value: 'workers', child: Text(t.menu_workers)),
              PopupMenuItem(value: 'settings', child: Text(t.menu_settings)),
              const PopupMenuItem(
                value: 'icons_preview',
                child: Text('[Dev] Icons checklist'),
              ),
            ],
          ),
          DevSeedButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60 + kTextTabBarHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thermostat),
                        const SizedBox(width: 6),
                        Text(t.line2_temperature),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.cloud),
                          label: Text(t.line2_weather),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Line2PropertyChip(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed, size: 16),
                        const SizedBox(width: 6),
                        gpsAsync.when(
                          data: (s) {
                            final text = (s == null)
                                ? 'GPS: —'
                                : 'GPS: ±${s.acc.toStringAsFixed(1)}m • σ ${s.stability.toStringAsFixed(2)}m';
                            return Text(text);
                          },
                          loading: () => const Text('GPS: …'),
                          error: (_, __) => const Text('GPS: —'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: t.tab_map),
                  Tab(text: t.tab_list),
                  Tab(text: t.tab_diary),
                  Tab(text: t.tab_farm_log),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const MapViewScreen(),
          const _PlaceholderView(label: 'List View (Points)'),
          const _PlaceholderView(label: 'Diary'),
          const _PlaceholderView(label: 'Farm Log'),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _onPlusMenu,
              icon: const Icon(Icons.add),
              label: Text(t.bottom_add),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              tooltip: t.bottom_refresh,
            ),
            PopupMenuButton<String>(
              tooltip: t.bottom_tools,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'nav', child: Text('Navigate')),
                const PopupMenuItem(
                  value: 'area',
                  child: Text('Area/Perimeter'),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Text('Export/Import'),
                ),
                const PopupMenuItem(
                  value: 'backup',
                  child: Text('Backup/Restore'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPlusMenu() async {
    final choice = await openBottomPlusMenu(context);
    if (choice == null) return;
    switch (choice) {
      case 'add_point':
        return _onAddPoint();
      case 'add_log':
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddLogScreen()));
        return;
      case 'add_diary':
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddDiaryTaskScreen()));
        return;
    }
  }

  Future<void> _onAddPoint() async {
    // Ensure active property exists
    final active = ref.read(activePropertyProvider);
    if (active.value == null) {
      // Use Line-2 chip picker for consistency
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or create a property first')),
      );
      return;
    }
    final method = await openAddPointMethodSheet(context);
    if (method == null) return;
    if (method == 'gps') {
      if (!mounted) return;
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AddPointGpsSheet(),
      );
    } else if (method == 'tap') {
      if (!mounted) return;
      // Transparent page route overlaying current map
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(children: [TapToPlaceOverlay()]),
          ),
        ),
      );
    }
  }

  void openTopMenu(BuildContext context, String value) async {
    switch (value) {
      case 'icons_preview':
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const IconPreviewScreen()));
        break;
      default:
        // Defer to existing global handler if present
        // fallback to existing wired function
        // already imported openTopMenu from app_menu_wiring; avoid recursion
        break;
    }
  }
}

// Legacy _CurrentPropertyChip replaced by Line2PropertyChip

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}
