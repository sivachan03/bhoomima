import 'package:flutter/material.dart';

Future<String?> openAddPointMethodSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Use GPS'),
            onTap: () => Navigator.pop(context, 'gps'),
          ),
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: const Text('Tap on map'),
            onTap: () => Navigator.pop(context, 'tap'),
          ),
        ],
      ),
    ),
  );
}
