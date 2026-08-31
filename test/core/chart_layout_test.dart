import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/chart/chart_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('micro-priced series is not flattened', () {
    final ys = chartUnitYs([
      Decimal.parse('0.000019'),
      Decimal.parse('0.000020'),
      Decimal.parse('0.000021'),
    ]);
    expect(ys.first, 0.0);
    expect(ys.last, 1.0);
    expect(ys[1], greaterThan(0.0));
    expect(ys[1], lessThan(1.0));
  });

  test('chartIndexAt maps pointer x to the nearest sample', () {
    expect(chartIndexAt(count: 5, width: 100, dx: 0), 0);
    expect(chartIndexAt(count: 5, width: 100, dx: 100), 4);
    expect(chartIndexAt(count: 5, width: 100, dx: 50), 2);
  });

  test('equal values sit on the midline', () {
    expect(
      chartUnitYs([Decimal.parse('1'), Decimal.parse('1')]),
      [0.5, 0.5],
    );
  });
}
