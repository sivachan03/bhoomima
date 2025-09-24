import 'package:flutter/material.dart';

Future<String?> openBottomPlusMenu(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_location_alt),
            title: const Text('Add point'),
            onTap: () => Navigator.pop(context, 'add_point'),
          ),
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Add log'),
            onTap: () => Navigator.pop(context, 'add_log'),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Add diary task'),
            onTap: () => Navigator.pop(context, 'add_diary'),
          ),
        ],
      ),
    ),
  );
}
