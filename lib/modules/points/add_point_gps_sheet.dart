import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state/active_property.dart';
import '../../core/services/gps_service.dart';
import '../shared/group_picker_sheet.dart';
import 'point_save.dart';
import 'point_naming.dart';
import '../../core/db/isar_service.dart';

class AddPointGpsSheet extends ConsumerStatefulWidget {
  const AddPointGpsSheet({super.key});
  @override
  ConsumerState<AddPointGpsSheet> createState() => _AddPointGpsSheetState();
}

class _AddPointGpsSheetState extends ConsumerState<AddPointGpsSheet> {
  StreamSubscription<GpsSample>? _sub;
  final _samples = <GpsSample>[];
  static const _maxSamples = 12;
  double? _bestLat, _bestLon, _bestAcc;
  DateTime? _bestSince;
  double _stability = 0;
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  PickedGroup? _group;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(gpsServiceProvider).stream.listen((s) {
      if (!mounted) return;
      _samples.add(s);
      while (_samples.length > _maxSamples) {
        _samples.removeAt(0);
      }
      final best = _samples.reduce((a, b) => a.acc < b.acc ? a : b);
      setState(() {
        final bestChanged =
            _bestLat != best.position.latitude ||
            _bestLon != best.position.longitude ||
            _bestAcc != best.acc;
        _bestLat = best.position.latitude;
        _bestLon = best.position.longitude;
        _bestAcc = best.acc;
        if (bestChanged) {
          _bestSince = DateTime.now();
        }
        _stability = _stabilityOf(_samples);
      });
    });
  }

  double _stabilityOf(List<GpsSample> xs) {
    if (xs.length < 3) return 0;
    double sum = 0, sum2 = 0;
    int n = 0;
    for (var i = 1; i < xs.length; i++) {
      final d = _hav(
        xs[i - 1].position.latitude,
        xs[i - 1].position.longitude,
        xs[i].position.latitude,
        xs[i].position.longitude,
      );
      sum += d;
      sum2 += d * d;
      n++;
    }
    final mean = sum / n;
    final varr = (sum2 / n) - (mean * mean);
    return math.sqrt(varr < 0 ? 0 : varr);
  }

  double _hav(double a, double b, double c, double d) {
    const R = 6371000.0;
    double r(double x) => x * math.pi / 180;
    final dLat = r(c - a), dLon = r(d - b);
    final q =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(r(a)) *
            math.cos(r(c)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * R * math.atan2(math.sqrt(q), math.sqrt(1 - q));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prop = ref.watch(activePropertyProvider).value;
    final canSave =
        !_saving &&
        _bestLat != null &&
        _bestLon != null &&
        _nameCtrl.text.trim().isNotEmpty &&
        prop != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add point (GPS)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Best lat/lon: ${_bestLat?.toStringAsFixed(6) ?? '—'}, ${_bestLon?.toStringAsFixed(6) ?? '—'}',
            ),
            Text(
              'Accuracy: ${_bestAcc?.toStringAsFixed(1) ?? '—'} m   Stability: ${_stability.toStringAsFixed(2)}',
            ),
            if (_bestSince != null)
              Text(
                'Best since: ${DateTime.now().difference(_bestSince!).inSeconds}s',
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.label_outline),
                    label: Text(_group == null ? 'Choose group' : _group!.name),
                    onPressed: () async {
                      final picked = await openGroupPickerSheet(context, ref);
                      if (picked != null) {
                        setState(() => _group = picked);
                        // Suggest name with continuity
                        final isar = await IsarService.open();
                        final suggestion = await suggestPointNameWithContinuity(
                          isar,
                          propertyId: prop!.id,
                          groupId: picked.id,
                          base: picked.name,
                        );
                        if (mounted) {
                          setState(() {
                            _nameCtrl.text = suggestion;
                            _nameCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: suggestion.length,
                            );
                          });
                          _nameFocus.requestFocus();
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _samples.clear();
                      _bestLat = null;
                      _bestLon = null;
                      _bestAcc = null;
                      _bestSince = null;
                      _stability = 0;
                    });
                  },
                  child: const Text('Reset best'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canSave
                      ? () async {
                          setState(() => _saving = true);
                          await savePointAndToast(
                            context: context,
                            ref: ref,
                            property: prop,
                            name: _nameCtrl.text.trim(),
                            groupId: _group?.id,
                            lat: _bestLat!,
                            lon: _bestLon!,
                            source: 'gps',
                          );
                          if (context.mounted) Navigator.pop(context, true);
                        }
                      : null,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
