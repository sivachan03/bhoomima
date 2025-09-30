import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalFilterState {
  final Set<int> groupIds;
  final bool partitionsIncluded;
  final bool inViewportOnly;
  final String search;
  final bool legendVisible;

  const GlobalFilterState({
    this.groupIds = const {},
    this.partitionsIncluded = false,
    this.inViewportOnly = false,
    this.search = '',
    this.legendVisible = false,
  });

  GlobalFilterState copyWith({
    Set<int>? groupIds,
    bool? partitionsIncluded,
    bool? inViewportOnly,
    String? search,
    bool? legendVisible,
  }) => GlobalFilterState(
    groupIds: groupIds ?? this.groupIds,
    partitionsIncluded: partitionsIncluded ?? this.partitionsIncluded,
    inViewportOnly: inViewportOnly ?? this.inViewportOnly,
    search: search ?? this.search,
    legendVisible: legendVisible ?? this.legendVisible,
  );

  Map<String, dynamic> toJson() => {
    'groupIds': groupIds.toList(),
    'partitionsIncluded': partitionsIncluded,
    'inViewportOnly': inViewportOnly,
    'search': search,
    'legendVisible': legendVisible,
  };

  factory GlobalFilterState.fromJson(Map<String, dynamic> m) =>
      GlobalFilterState(
        groupIds: {
          ...(m['groupIds'] as List?)?.map((e) => e as int) ?? const <int>[],
        },
        partitionsIncluded: m['partitionsIncluded'] == true,
        inViewportOnly: m['inViewportOnly'] == true,
        search: (m['search'] as String?) ?? '',
        legendVisible: m['legendVisible'] == true,
      );

  static String encode(GlobalFilterState s) => jsonEncode(s.toJson());
  static GlobalFilterState decode(String? s) {
    if (s == null || s.isEmpty) return const GlobalFilterState();
    try {
      return GlobalFilterState.fromJson(jsonDecode(s));
    } catch (_) {
      return const GlobalFilterState();
    }
  }
}

final globalFilterProvider = StateProvider<GlobalFilterState>(
  (_) => const GlobalFilterState(),
);
