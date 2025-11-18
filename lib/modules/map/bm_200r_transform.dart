import 'dart:math' as math;

class MapTransform {
  final double tx;
  final double ty;
  final double scale;
  final double theta; // radians

  const MapTransform({
    required this.tx,
    required this.ty,
    required this.scale,
    required this.theta,
  });

  MapTransform copyWith({
    double? tx,
    double? ty,
    double? scale,
    double? theta,
  }) {
    return MapTransform(
      tx: tx ?? this.tx,
      ty: ty ?? this.ty,
      scale: scale ?? this.scale,
      theta: theta ?? this.theta,
    );
  }

  MapTransform rotatedBy(double dTheta) {
    final newTheta = theta + dTheta;
    // Normalize to [-π, π] just for sanity.
    final wrapped = ((newTheta + math.pi) % (2 * math.pi)) - math.pi;
    return copyWith(theta: wrapped);
  }

  @override
  String toString() =>
      'MapTransform(tx=$tx, ty=$ty, scale=$scale, theta=$theta)';
}
