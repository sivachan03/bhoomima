import 'package:flutter/material.dart';

class BhoomiSearchDelegate extends SearchDelegate<String?> {
  BhoomiSearchDelegate({String? initial}) {
    query = initial ?? '';
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    close(context, query.trim());
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text(
        query.isEmpty
            ? 'Type a name or group…'
            : 'Tap enter to search “$query”',
      ),
    );
  }
}
