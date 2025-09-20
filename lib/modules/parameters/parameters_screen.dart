import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/parameters/log_subtype.dart';
import '../../core/models/parameters/log_type.dart';
import '../../core/models/parameters/point_group_category.dart';
import '../../core/models/parameters/property_type.dart';
import '../../core/models/parameters/unit_def.dart';
import '../../core/repos/parameters_repo.dart';

final _repoProvider = Provider((_) => ParametersRepo());

class ParametersScreen extends ConsumerWidget {
  const ParametersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Parameters'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Logs'),
              Tab(text: 'Map'),
              Tab(text: 'Units'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Seed from CSV (BM-55)',
              onPressed: () async {
                await ref
                    .read(_repoProvider)
                    .seedFromCsvAsset('assets/i18n/BM-55_parameters_seed.csv');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seed complete')),
                  );
                }
              },
            ),
          ],
        ),
        body: const TabBarView(children: [_LogsTab(), _MapTab(), _UnitsTab()]),
        floatingActionButton: const SizedBox.shrink(),
      ),
    );
  }
}

class _LogsTab extends ConsumerWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(_repoProvider);
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<LogType>>(
            stream: repo.watchLogTypes(),
            builder: (context, snap) {
              final types = snap.data ?? const [];
              return ListView.builder(
                itemCount: types.length,
                itemBuilder: (_, i) {
                  final t = types[i];
                  return ExpansionTile(
                    title: Text(
                      'Type: ${t.code}${t.locked ? " (locked)" : ""}',
                    ),
                    trailing: t.locked
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () async {
                              try {
                                await repo.deleteLogType(t.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                          ),
                    children: [
                      StreamBuilder<List<LogSubtype>>(
                        stream: repo.watchLogSubtypes(t.id),
                        builder: (context, snap2) {
                          final subs = snap2.data ?? const [];
                          return Column(
                            children: [
                              for (final s in subs)
                                ListTile(
                                  title: Text(
                                    'Subtype: ${s.code}${s.locked ? " (locked)" : ""}',
                                  ),
                                  trailing: s.locked
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              repo.deleteLogSubtype(s.id),
                                        ),
                                ),
                              if (!t.locked)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'New subtype code',
                                          ),
                                          onSubmitted: (val) {
                                            if (val.trim().isNotEmpty) {
                                              repo.addLogSubtype(
                                                t.id,
                                                val.trim(),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'New type code (e.g., INCOME)',
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      repo.addLogType(val.trim());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapTab extends ConsumerWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(_repoProvider);
    return StreamBuilder<List<PointGroupCategory>>(
      stream: repo.watchGroupCats(),
      builder: (context, s1) {
        final cats = s1.data ?? const [];
        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  ...cats.map(
                    (c) => ListTile(
                      title: Text(
                        'Group: ${c.code}${c.locked ? " (locked)" : ""}',
                      ),
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
            StreamBuilder<List<PropertyType>>(
              stream: repo.watchPropertyTypes(),
              builder: (context, s2) {
                final types = s2.data ?? const [];
                return Column(
                  children: [
                    const ListTile(title: Text('Property Types')),
                    ...types.map(
                      (p) => ListTile(
                        title: Text('${p.code}${p.locked ? " (locked)" : ""}'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _UnitsTab extends ConsumerWidget {
  const _UnitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(_repoProvider);
    return StreamBuilder<List<UnitDef>>(
      stream: repo.watchUnits(),
      builder: (context, snap) {
        final units = snap.data ?? const [];
        return ListView.builder(
          itemCount: units.length,
          itemBuilder: (_, i) {
            final u = units[i];
            return ListTile(
              title: Text(
                '${u.code} — ${u.kind}${u.locked ? " (locked)" : ""}',
              ),
            );
          },
        );
      },
    );
  }
}
