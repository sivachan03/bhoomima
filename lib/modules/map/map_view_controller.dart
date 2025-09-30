import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapViewController extends ChangeNotifier {
  double scale = 1.0; // zoom
  double rotation = 0.0; // radians
  Offset pan = Offset.zero; // screen-space pan after projection

  void update({Offset? pan, double? scale, double? rotation}) {
    var changed = false;
    if (pan != null && pan != this.pan) {
      this.pan = pan;
      changed = true;
    }
    if (scale != null && scale != this.scale) {
      this.scale = scale;
      changed = true;
    }
    if (rotation != null && rotation != this.rotation) {
      this.rotation = rotation;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Matrix4 toMatrix4() {
    final m = Matrix4.identity();
    m.translate(pan.dx, pan.dy);
    m.rotateZ(rotation);
    m.scale(scale);
    return m;
  }
}

final mapViewController = ChangeNotifierProvider<MapViewController>((ref) {
  return MapViewController();
});
