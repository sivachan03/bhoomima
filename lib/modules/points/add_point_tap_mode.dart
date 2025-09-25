import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state/active_property.dart';
import '../../core/services/gps_service.dart';
import '../shared/group_picker_sheet.dart';
import 'point_save.dart';
import 'point_naming.dart';
import '../../core/db/isar_service.dart';

class TapToPlaceOverlay extends ConsumerWidget {
  const TapToPlaceOverlay({super.key});

  Future<GpsSample?> _getOnce(WidgetRef ref) async {
    final svc = ref.read(gpsServiceProvider);
    final c = Completer<GpsSample?>();
    late final StreamSubscription<GpsSample> sub;
    sub = svc.stream.listen((s) {
      if (!c.isCompleted) {
        c.complete(s);
        sub.cancel();
      }
    });
    return c.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (d) async {
          final prop = ref.read(activePropertyProvider).value;
          if (prop == null) return;
          final nameCtrl = TextEditingController();
          PickedGroup? pickedGroup;
          final ok =
              await showDialog<bool>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text('Add point (Tap)'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setStateSb) => OutlinedButton.icon(
                            icon: const Icon(Icons.label_outline),
                            label: Text(
                              pickedGroup == null
                                  ? 'Choose group'
                                  : pickedGroup!.name,
                            ),
                            onPressed: () async {
                              final pg = await openGroupPickerSheet(
                                context,
                                ref,
                              );
                              if (pg != null) {
                                pickedGroup = pg;
                                // Suggest name
                                final isar = await IsarService.open();
                                final suggestion =
                                    await suggestPointNameWithContinuity(
                                      isar,
                                      propertyId: prop.id,
                                      groupId: pg.id,
                                      base: pg.name,
                                    );
                                nameCtrl.text = suggestion;
                                nameCtrl.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: suggestion.length,
                                );
                                setStateSb(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              ) ??
              false;
          final name = nameCtrl.text;
          if (!ok || name.trim().isEmpty) return;
          final sample = await _getOnce(ref);
          if (sample == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GPS not ready. Try again.')),
              );
            }
            return;
          }
          await savePointAndToast(
            context: context,
            ref: ref,
            property: prop,
            name: name.trim(),
            groupId: pickedGroup?.id,
            lat: sample.position.latitude,
            lon: sample.position.longitude,
            source: 'tap+gps',
          );
          if (context.mounted) Navigator.pop(context);
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Tap on map to place point (GPS sets coordinates)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
