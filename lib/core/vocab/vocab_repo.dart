import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vocabRepoProvider = Provider<VocabRepository>((ref) => VocabRepository());
final vocabLoadedProvider = FutureProvider<void>((ref) async {
  await ref.read(vocabRepoProvider).loadFromAssets();
});

class VocabRepository {
  // domain -> code -> locale -> label
  final Map<String, Map<String, Map<String, String>>> _index = {};

  Future<void> loadFromAssets() async {
    final raw = await rootBundle.loadString('assets/seed_vocab.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final terms = (jsonMap['terms'] as List).cast<Map<String, dynamic>>();
    for (final t in terms) {
      final domain = t['domain'] as String;
      final code = t['code'] as String;
      final labels = (t['labels'] as Map).cast<String, dynamic>();
      _index.putIfAbsent(domain, () => {});
      _index[domain]![code] = labels.map((k, v) => MapEntry(k, v.toString()));
    }
  }

  String label({required String domain, required String code, required Locale locale}) {
    final loc = locale.languageCode;
    final en = 'en';
    final byCode = _index[domain]?[code];
    if (byCode == null) return code; // fallback to code
    return byCode[loc] ?? byCode[en] ?? code;
  }
}

class VocabBoot extends ConsumerWidget {
  const VocabBoot({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(vocabLoadedProvider);
    return snap.when(
      data: (_) => child,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Vocab load error: $e'))),
    );
  }
}