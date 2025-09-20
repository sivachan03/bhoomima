import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
// import '../vocab/vocab_repo.dart';
import '../state/current_property.dart';
import '../repos/property_repo.dart';
import '../../modules/properties/properties_screen.dart';
import '../../modules/groups/groups_screen.dart';
import '../../modules/parameters/parameters_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/map/map_view.dart';

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
            onSelected: (v) {
              switch (v) {
                case 'props':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PropertiesScreen()),
                  );
                  break;
                case 'groups':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroupsScreen()),
                  );
                  break;
                case 'params':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ParametersScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'props', child: Text(t.menu_properties)),
              PopupMenuItem(value: 'groups', child: Text(t.menu_groups)),
              const PopupMenuItem(value: 'params', child: Text('Parameters')),
              PopupMenuItem(value: 'workers', child: Text(t.menu_workers)),
              PopupMenuItem(value: 'settings', child: Text(t.menu_settings)),
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
                    _CurrentPropertyChip(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${t.line2_gps}: ${t.gps_accuracy}/ ${t.gps_stability}',
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
              onPressed: _onAddPressed,
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

  void _onAddPressed() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location),
              title: Text(t.add_point),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: Text(t.add_log),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(t.add_diary),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPropertyChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final currentId = ref.watch(currentPropertyIdProvider);
    Widget label;
    if (currentId == null) {
      label = Text(t.line2_property);
    } else {
      final propAsync = ref.watch(currentPropertyProvider(currentId));
      label = propAsync.when(
        data: (p) => Text(p?.name ?? t.line2_property),
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => Text(t.line2_property),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PropertiesScreen()));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home, size: 16),
          const SizedBox(width: 6),
          label,
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}
