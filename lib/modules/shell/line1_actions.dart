import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../filter/filter_sheet.dart';
import '../filter/global_filter.dart';
import '../filter/filter_persistence.dart';
import '../search/search_delegate.dart';

class Line1Actions extends ConsumerWidget {
  const Line1Actions({super.key, required this.propertyId});
  final int propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(globalFilterProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.filter_alt),
          tooltip: 'Filter',
          onPressed: () =>
              openGlobalFilterSheet(context, ref, propertyId: propertyId),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () async {
            final initial = state.search;
            final picked = await showSearch<String?>(
              context: context,
              delegate: BhoomiSearchDelegate(initial: initial),
            );
            if (picked == null) return;
            final next = state.copyWith(search: picked.trim());
            ref.read(globalFilterProvider.notifier).state = next;
            await ref.read(filterPersistence).save(next);
          },
        ),
        if (state.search.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InputChip(
              label: Text('“${state.search}”'),
              onDeleted: () async {
                final next = state.copyWith(search: '');
                ref.read(globalFilterProvider.notifier).state = next;
                await ref.read(filterPersistence).save(next);
              },
            ),
          ),
      ],
    );
  }
}
