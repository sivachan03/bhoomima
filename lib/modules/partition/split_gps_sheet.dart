import 'package:flutter/material.dart';
import '../../core/services/gps_service.dart';

typedef TwoGpsDone =
    void Function((double lat, double lon) a, (double lat, double lon) b);

class SplitGpsSheet extends StatefulWidget {
  const SplitGpsSheet({super.key, required this.gps, required this.onDone});
  final GpsService gps;
  final TwoGpsDone onDone;

  @override
  State<SplitGpsSheet> createState() => _SplitGpsSheetState();
}

class _SplitGpsSheetState extends State<SplitGpsSheet> {
  (double, double)? a, b;
  String status = 'Ready';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Split via GPS', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(status),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final fix = await widget.gps.getOnce();
                  setState(() {
                    a = (fix.position.latitude, fix.position.longitude);
                    status = 'Point A captured';
                  });
                },
                child: const Text('Set A'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final fix = await widget.gps.getOnce();
                  setState(() {
                    b = (fix.position.latitude, fix.position.longitude);
                    status = 'Point B captured';
                  });
                },
                child: const Text('Set B'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (a != null && b != null)
                ? () {
                    widget.onDone(a!, b!);
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Use A & B'),
          ),
        ],
      ),
    );
  }
}
