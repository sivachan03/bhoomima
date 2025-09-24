import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state/active_property.dart';
import '../properties/property_picker.dart';

class Line2PropertyChip extends ConsumerWidget {
  const Line2PropertyChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activePropertyProvider);
    return active.when(
      loading: () => const Text('Property: …'),
      error: (_, __) => const Text('Property: (error)'),
      data: (p) => InkWell(
        onTap: () => openPropertyPicker(context, ref),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined, size: 16),
            const SizedBox(width: 6),
            Text(
              'Property: ${p?.name ?? '(select)'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
    );
  }
}
