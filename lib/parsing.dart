// parsing.dart

import 'dart:io';

enum GestureMode { pan, zoom, rotate, unknown }

// Legacy flattened frame used by older checks/tools.
class FlatFrame {
  final int lineNo;
  final GestureMode mode;
  final bool? zoomOk;
  final bool? rotateOk;
  final bool? veto;
  final bool? freeze;
  final double? zoomRate;
  final double? rotRate;
  final double? dTheta;
  final double? dScale;
  final double? panX;
  final double? panY;

  FlatFrame({
    required this.lineNo,
    required this.mode,
    this.zoomOk,
    this.rotateOk,
    this.veto,
    this.freeze,
    this.zoomRate,
    this.rotRate,
    this.dTheta,
    this.dScale,
    this.panX,
    this.panY,
  });
}

GestureMode _parseMode(String s) {
  switch (s.toLowerCase()) {
    case 'pan':
      return GestureMode.pan;
    case 'zoom':
      return GestureMode.zoom;
    case 'rotate':
      return GestureMode.rotate;
    default:
      return GestureMode.unknown;
  }
}

double? _numOrNull(String? s) {
  if (s == null) return null;
  return double.tryParse(s);
}

// Legacy flattened parser preserved as parseLogFlat.
List<FlatFrame> parseLogFlat(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw Exception('Log file not found: $path');
  }
  final frames = <FlatFrame>[];
  final bmRegex = RegExp(
    r'\[BM-199\]\s+mode=(\w+).*?\bzoomOk=(\w+)\b.*?\brotateOk=(\w+)\b.*?\bveto=(\w+)'
    r'(?:.*?\bfreeze=(\w+))?(?:.*?\bzoomRate=([-+0-9\.]+))?(?:.*?\brotRate=([-+0-9\.]+))?',
  );
  final applyRegex = RegExp(
    r'\[APPLY\]\s+.*?\bmode=(\w+)'
    r'(?:.*?panPx=\(([-+0-9\.]+),([-+0-9\.]+)\))?'
    r'(?:.*?\bdS=([-+0-9\.]+))?'
    r'(?:.*?\b(?:dθ|dTheta)=([-+0-9\.]+))?',
  );

  int lineNo = 0;
  for (final raw in file.readAsLinesSync()) {
    lineNo++;
    final line = raw.trim();
    if (line.isEmpty) continue;

    final bm = bmRegex.firstMatch(line);
    if (bm != null) {
      frames.add(
        FlatFrame(
          lineNo: lineNo,
          mode: _parseMode(bm.group(1) ?? ''),
          zoomOk: (bm.group(2) ?? '').toLowerCase() == 'true',
          rotateOk: (bm.group(3) ?? '').toLowerCase() == 'true',
          veto: (bm.group(4) ?? '').toLowerCase() == 'true',
          freeze: (bm.group(5) ?? '').toLowerCase() == 'true',
          zoomRate: _numOrNull(bm.group(6)),
          rotRate: _numOrNull(bm.group(7)),
        ),
      );
      continue;
    }

    final ap = applyRegex.firstMatch(line);
    if (ap != null) {
      frames.add(
        FlatFrame(
          lineNo: lineNo,
          mode: _parseMode(ap.group(1) ?? ''),
          panX: _numOrNull(ap.group(2)),
          panY: _numOrNull(ap.group(3)),
          dScale: _numOrNull(ap.group(4)),
          dTheta: _numOrNull(ap.group(5)),
        ),
      );
      continue;
    }
  }
  return frames;
}

// =====================
// Event-based parsing API (non-breaking addition)
// =====================

// Rich regexes for structured events
final RegExp _reBmEvt = RegExp(
  r'\[BM-199\]\s+mode=(\w+)\s+zoomOk=(\w+)\s+rotateOk=(\w+)\s+veto=(\w+)'
  r'(?:\s+freeze=(\w+))?(?:\s+zoomRate=([-+]?\d*\.?\d+))?(?:\s+rotRate=([-+]?\d*\.?\d+))?',
);

// Order-agnostic APPLY: allow arbitrary ordering of fields.
final RegExp _reApply = RegExp(
  r'\[APPLY\].*?mode=(\w+)'
  r'(?:.*?panPx=\(([-+]?\d*\.?\d+),([-+]?\d*\.?\d+)\))?'
  r'(?:.*?sumPan=\(([-+]?\d*\.?\d+),([-+]?\d*\.?\d+)\))?'
  r'(?:.*?dS=([-+]?\d*\.?\d+))?'
  r'(?:.*?dθ=([-+]?\d*\.?\d+))?'
  r'(?:.*?→\s+tx=([-+]?\d*\.?\d+)\s+ty=([-+]?\d*\.?\d+))?'
  r'(?:.*?scale=([-+]?\d*\.?\d+))?'
  r'(?:.*?rot=([-+]?\d*\.?\d+)[°]?)?'
  r'(?:.*?totalRotDeg=([-+]?\d*\.?\d+))?',
  dotAll: true,
);

final RegExp _reFreezeEvt = RegExp(r'\[FREEZE\]\s+(start|active)\b');

// Order-agnostic PARGATE: only require mode + ready flags.
final RegExp _reParGate = RegExp(
  r'\[PARGATE\].*?mode=(\w+).*?zoomReady=(\w+)\s+rotateReady=(\w+)',
  dotAll: true,
);

class BmEvent {
  final String mode;
  final bool zoomOk, rotateOk, veto;
  final bool? freeze;
  final double zoomRate, rotRate;
  final int lineNo;
  BmEvent({
    required this.mode,
    required this.zoomOk,
    required this.rotateOk,
    required this.veto,
    required this.freeze,
    required this.zoomRate,
    required this.rotRate,
    required this.lineNo,
  });
}

class ApplyEvent {
  final String mode;
  final double dS, dTheta;
  final double? panPxX, panPxY;
  final double? tx, ty;
  final double? scale, rotDeg;
  final int lineNo;
  ApplyEvent({
    required this.mode,
    required this.dS,
    required this.dTheta,
    required this.panPxX,
    required this.panPxY,
    required this.tx,
    required this.ty,
    required this.scale,
    required this.rotDeg,
    required this.lineNo,
  });
}

class FreezeEvent {
  final String kind; // start | active
  final int lineNo;
  FreezeEvent(this.kind, this.lineNo);
}

class ParGateEvent {
  final String mode;
  final bool zoomReady, rotateReady;
  final double? cosParLP, dLogLP, dThetaLP;
  final int lineNo;
  ParGateEvent({
    required this.mode,
    required this.zoomReady,
    required this.rotateReady,
    required this.cosParLP,
    required this.dLogLP,
    required this.dThetaLP,
    required this.lineNo,
  });
}

class EventFrame {
  final int lineNo;
  final BmEvent? bm;
  final ApplyEvent? apply;
  final FreezeEvent? freeze;
  final ParGateEvent? gate;
  EventFrame({
    required this.lineNo,
    this.bm,
    this.apply,
    this.freeze,
    this.gate,
  });
}

List<EventFrame> parseLogEvents(File f) {
  final frames = <EventFrame>[];
  final lines = f.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    BmEvent? bm;
    ApplyEvent? ap;
    FreezeEvent? fr;
    ParGateEvent? gt;

    final mb = _reBmEvt.firstMatch(line);
    if (mb != null) {
      bm = BmEvent(
        mode: mb.group(1)!,
        zoomOk: (mb.group(2) ?? '') == 'true',
        rotateOk: (mb.group(3) ?? '') == 'true',
        veto: (mb.group(4) ?? '') == 'true',
        freeze: mb.group(5) == null ? null : (mb.group(5) == 'true'),
        zoomRate: double.tryParse(mb.group(6) ?? '') ?? 0.0,
        rotRate: double.tryParse(mb.group(7) ?? '') ?? 0.0,
        lineNo: i + 1,
      );
    }

    final ma = _reApply.firstMatch(line);
    if (ma != null) {
      ap = ApplyEvent(
        mode: ma.group(1)!,
        panPxX: double.tryParse(ma.group(2) ?? ''),
        panPxY: double.tryParse(ma.group(3) ?? ''),
        dS: double.tryParse(ma.group(6) ?? '') ?? 0.0,
        dTheta: double.tryParse(ma.group(7) ?? '') ?? 0.0,
        tx: double.tryParse(ma.group(8) ?? ''),
        ty: double.tryParse(ma.group(9) ?? ''),
        scale: double.tryParse(ma.group(10) ?? ''),
        rotDeg: double.tryParse(ma.group(11) ?? ''),
        lineNo: i + 1,
      );
    }

    final mf = _reFreezeEvt.firstMatch(line);
    if (mf != null) {
      fr = FreezeEvent(mf.group(1)!, i + 1);
    }

    final mg = _reParGate.firstMatch(line);
    if (mg != null) {
      gt = ParGateEvent(
        mode: mg.group(1)!,
        // Order-agnostic version does not currently capture cosParLP/dLogLP/dThetaLP.
        cosParLP: null,
        dLogLP: null,
        dThetaLP: null,
        zoomReady: (mg.group(2) ?? '') == 'true',
        rotateReady: (mg.group(3) ?? '') == 'true',
        lineNo: i + 1,
      );
    }

    if (bm != null || ap != null || fr != null || gt != null) {
      frames.add(
        EventFrame(lineNo: i + 1, bm: bm, apply: ap, freeze: fr, gate: gt),
      );
    }
  }
  return frames;
}

// Preferred API: parseLog -> EventFrame list, plus a Frame alias for invariants.
typedef Frame = EventFrame;

List<Frame> parseLog(String path) {
  final f = File(path);
  if (!f.existsSync()) {
    throw Exception('Log file not found: $path');
  }
  return parseLogEvents(f);
}
