import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';

import '../../core/db/isar_service.dart';
import '../../core/models/icon_item.dart';

class IconPreviewScreen extends ConsumerStatefulWidget {
  const IconPreviewScreen({super.key});

  @override
  ConsumerState<IconPreviewScreen> createState() => _IconPreviewScreenState();
}

class _IconPreviewScreenState extends ConsumerState<IconPreviewScreen> {
  String _query = '';
  double _size = 24;
  bool _showDark = true;
  bool _showLight = true;
  String _sort = 'code'; // 'code' or 'label'

  final _sizes = const [16.0, 24.0, 32.0, 48.0];

  Future<Isar> _db() => IsarService.open();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon checklist'),
        actions: [
          PopupMenuButton<double>(
            initialValue: _size,
            onSelected: (v) => setState(() => _size = v),
            itemBuilder: (_) => _sizes
                .map(
                  (s) =>
                      PopupMenuItem(value: s, child: Text('Size ${s.toInt()}')),
                )
                .toList(),
            icon: const Icon(Icons.format_size),
          ),
          PopupMenuButton<String>(
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'code', child: Text('Sort by code')),
              PopupMenuItem(value: 'label', child: Text('Sort by label')),
            ],
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            icon: Icon(_showLight ? Icons.wb_sunny : Icons.wb_sunny_outlined),
            tooltip: 'Toggle light swatch',
            onPressed: () => setState(() => _showLight = !_showLight),
          ),
          IconButton(
            icon: Icon(
              _showDark ? Icons.nightlight_round : Icons.nightlight_outlined,
            ),
            tooltip: 'Toggle dark swatch',
            onPressed: () => setState(() => _showDark = !_showDark),
          ),
        ],
      ),
      body: FutureBuilder<List<IconItem>>(
        future: _db().then(
          (db) => db.iconItems.filter().deprecatedEqualTo(false).findAll(),
        ),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snap.data!;
          if (_query.trim().isNotEmpty) {
            final q = _query.toLowerCase();
            items = items
                .where(
                  (e) =>
                      (e.code.toLowerCase().contains(q)) ||
                      ((e.labelEn ?? '').toLowerCase().contains(q)) ||
                      ((e.category ?? '').toLowerCase().contains(q)),
                )
                .toList();
          }
          items.sort((a, b) {
            if (_sort == 'label') {
              return (a.labelEn ?? a.code).toLowerCase().compareTo(
                (b.labelEn ?? b.code).toLowerCase(),
              );
            }
            return a.code.toLowerCase().compareTo(b.code.toLowerCase());
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by code/label/category',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(
                      'Count: ${items.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Size: ${_size.toInt()} px',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return _IconRow(
                      code: it.code,
                      label: it.labelEn ?? it.code,
                      assetPath: it.assetPath ?? '',
                      size: _size,
                      showLight: _showLight,
                      showDark: _showDark,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  final String code;
  final String label;
  final String assetPath;
  final double size;
  final bool showLight;
  final bool showDark;

  const _IconRow({
    required this.code,
    required this.label,
    required this.assetPath,
    required this.size,
    required this.showLight,
    required this.showDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasAsset = assetPath.isNotEmpty;
    final iconWidget = hasAsset
        ? SvgPicture.asset(assetPath, width: size, height: size)
        : const Icon(Icons.location_on);

    Widget swatch(Color bg) => Container(
      height: size + 12,
      width: size + 12,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: iconWidget,
    );

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLight) swatch(Colors.white),
            if (showDark) swatch(const Color(0xFF1E1E1E)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    code,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    assetPath.isEmpty ? 'No asset' : assetPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (!hasAsset)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'MISSING ASSET',
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
