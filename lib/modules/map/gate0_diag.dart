// Legacy Gate0 frame tracker (kept for compatibility with older logs).
class Gate0Diag {
  static int _frameSeq = 0;
  static int bumpFrame() {
    _frameSeq += 1;
    return _frameSeq;
  }

  static int peekNext() => _frameSeq + 1;
  static int current() => _frameSeq;
}

// Small atomic-like int wrapper with increment and get.
// Removed AtomicInt and G0Seq sequencing; reverting to legacy-only Gate0Diag.
class AtomicInt {
  int _v;
  AtomicInt([int initial = 0]) : _v = initial;
  int inc() => ++_v;
  int get() => _v;
}

// Unified Gate-0 sequencing shared across APPLY and PAINT.
// APPLY must set epoch to applySeq.inc(); PAINT increments paintSeq and
// snapshots lastAppliedSeqAtPaint = applySeq.get().
class G0Seq {
  static final AtomicInt applySeq = AtomicInt(0);
  static int paintSeq = 0;
  static int lastAppliedSeqAtPaint = 0;
}
