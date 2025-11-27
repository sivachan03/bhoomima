# bhoomima

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## What this is and what it is not

Is:

- A clean, mathematically consistent 2-finger engine.
- Matching the behavioural contract you described from Java:
	- 2 fingers → pan + zoom + rotate.
	- 1 finger → no geometry.
- No modes, no PhotoView, no state machine.

Is not (yet):

- A byte-for-byte port of your original Java code (we still don’t have it here).
- Guaranteed identical feel to the Android version if your MapPainter uses a different transform order.

Code location: `lib/modules/map/java_style/` (engine, applier, and view).
# bhoomima
