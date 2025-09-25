import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalFilterState {
  final bool partitionsIncluded; // controls labels visibility
  final bool legendVisible; // legend toggle on map
  const GlobalFilterState({
    this.partitionsIncluded = false,
    this.legendVisible = false,
  });

  GlobalFilterState copyWith({bool? partitionsIncluded, bool? legendVisible}) =>
      GlobalFilterState(
        partitionsIncluded: partitionsIncluded ?? this.partitionsIncluded,
        legendVisible: legendVisible ?? this.legendVisible,
      );
}

final globalFilterProvider = StateProvider<GlobalFilterState>(
  (_) => const GlobalFilterState(),
);
