import 'package:decimal/decimal.dart';

/// Maps closes to 0..1 (0 = min, 1 = max) for painting.
///
/// Equal values sit on the midline. Span is the actual min/max range so
/// micro-priced assets (BONK, PEPE) are not flattened.
List<double> chartUnitYs(List<Decimal> points) {
  if (points.isEmpty) {
    return const [];
  }
  final values = [for (final point in points) double.parse(point.toString())];
  var min = values.first;
  var max = values.first;
  for (final value in values) {
    if (value < min) {
      min = value;
    }
    if (value > max) {
      max = value;
    }
  }
  if (min == max) {
    return List<double>.filled(values.length, 0.5);
  }
  final span = max - min;
  return [for (final value in values) (value - min) / span];
}
