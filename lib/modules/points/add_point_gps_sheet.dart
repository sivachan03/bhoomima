import 'package:flutter/material.dart';

class AddPointGpsResult {
  final double lat, lon;
  final String name;
  final int? groupId;
  AddPointGpsResult({
    required this.lat,
    required this.lon,
    required this.name,
    this.groupId,
  });
}

typedef OnSavePoint = Future<void> Function(AddPointGpsResult r);

class AddPointGpsSheet extends StatefulWidget {
  final OnSavePoint onSave;
  const AddPointGpsSheet({super.key, required this.onSave});
  @override
  State<AddPointGpsSheet> createState() => _AddPointGpsSheetState();
}

class _AddPointGpsSheetState extends State<AddPointGpsSheet> {
  String _name = '';
  String? _groupIdStr;
  double? _lat, _lon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // TODO: replace stubs with live values from your GpsService
    _lat = 11.111111;
    _lon = 76.222222;
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        !_saving && _lat != null && _lon != null && _name.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add point (GPS)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Lat: ${_lat?.toStringAsFixed(6) ?? '—'}  Lon: ${_lon?.toStringAsFixed(6) ?? '—'}',
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (v) => setState(() => _name = v),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Group Id (optional)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  setState(() => _groupIdStr = v.isEmpty ? null : v),
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
                          await widget.onSave(
                            AddPointGpsResult(
                              lat: _lat!,
                              lon: _lon!,
                              name: _name.trim(),
                              groupId: _groupIdStr == null
                                  ? null
                                  : int.tryParse(_groupIdStr!),
                            ),
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
