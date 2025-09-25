import 'package:isar/isar.dart';
import '../../core/models/point.dart';

/// Suggest a point name with continuity semantics.
/// Rules:
/// 1. If the most recent point in the chosen group exists, continue its base.
///    "X" -> "X 2"; "X 3" -> "X 4".
/// 2. Else fall back to provided [base] (usually group name): "Base 1", "Base 2"...
/// 3. Else final fallback: "Pt 1".
Future<String> suggestPointNameWithContinuity(
  Isar db, {
  required int
  propertyId, // (propertyId currently not stored directly on Point; using group scope)
  int? groupId,
  String? base,
}) async {
  // Continuity based on latest point in same group (if group selected)
  if (groupId != null) {
    final latest = await db.points
        .filter()
        .groupIdEqualTo(groupId)
        .sortByCreatedAtDesc()
        .findFirst();
    if (latest != null) {
      final nextFromLatest = _nextFrom(latest.name);
      if (nextFromLatest != null) return nextFromLatest;
    }
  }

  // Fallback: compute next from base within the same group
  final computed = await _nextFromBase(db, groupId: groupId, base: base);
  if (computed != null) return computed;

  return 'Pt 1';
}

/// If name is "X" => "X 2"; if "X N" => "X (N+1)"; else null.
String? _nextFrom(String name) {
  final n = name.trim();
  if (n.isEmpty) return null;
  final parts = n.split(RegExp(r'\s+'));
  final last = parts.isNotEmpty ? parts.last : '';
  final maybeNum = int.tryParse(last);
  if (maybeNum != null) {
    final base = n.substring(0, n.length - last.length).trimRight();
    final next = maybeNum + 1;
    return base.isEmpty ? null : '$base $next';
  } else {
    // No number suffix; treat as first -> add 2
    return '$n 2';
  }
}

/// Scan existing to find max index for base; return "base next".
Future<String?> _nextFromBase(Isar db, {int? groupId, String? base}) async {
  final b = (base == null || base.trim().isEmpty) ? 'Pt' : base.trim();
  final q = (groupId == null)
      ? db.points
            .where() // no group filter: unlikely path; continuity relies on group
      : db.points.filter().groupIdEqualTo(groupId);
  final list = await q.findAll();
  int maxIdx = 0;
  bool seenBare = false;
  final lower = b.toLowerCase();
  for (final p in list) {
    final n = p.name.trim();
    if (n.isEmpty) continue;
    if (n.toLowerCase() == lower) {
      seenBare = true;
      if (maxIdx < 1) maxIdx = 1;
      continue;
    }
    if (n.toLowerCase().startsWith('$lower ')) {
      final tail = n.substring(b.length).trim();
      final idx = int.tryParse(tail) ?? 0;
      if (idx > maxIdx) maxIdx = idx;
    }
  }
  final next = maxIdx + 1;
  if (!seenBare && next == 1) return '$b 1';
  return '$b $next';
}
