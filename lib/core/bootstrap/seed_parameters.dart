import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repos/parameters_repo.dart';

Future<void> seedParametersIfEmpty(WidgetRef ref) async {
  final repo = ParametersRepo();
  // quick heuristic: seed all from CSV (idempotent due to checks in repo)
  await repo.seedFromCsvAsset('assets/i18n/BM-55_parameters_seed.csv');
}
