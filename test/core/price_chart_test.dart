import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/widgets/price_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final points = [
    Decimal.parse('10'),
    Decimal.parse('12'),
    Decimal.parse('11'),
    Decimal.parse('14'),
  ];

  Widget chart({
    required List<Decimal> series,
    List<DateTime>? times,
    ValueChanged<int?>? onScrub,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: PriceChart(
            points: series,
            times: times,
            height: 120,
            onScrub: onScrub,
          ),
        ),
      ),
    );
  }

  testWidgets('touch shows a marker until the pointer lifts', (tester) async {
    int? selected;
    await tester.pumpWidget(
      chart(series: points, onScrub: (index) => selected = index),
    );

    final center = tester.getCenter(find.byType(PriceChart));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(find.byKey(const Key('chart_scrub_marker')), findsOneWidget);
    expect(selected, isNonNegative);

    await gesture.up();
    await tester.pump();
    expect(find.byKey(const Key('chart_scrub_marker')), findsNothing);
    expect(selected, isNull);
  });

  testWidgets('hover shows a marker and leaving restores the live point', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      chart(series: points, onScrub: (index) => selected = index),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    final box = tester.getRect(find.byType(PriceChart));
    await gesture.moveTo(box.center);
    await tester.pump();
    expect(find.byKey(const Key('chart_scrub_marker')), findsOneWidget);
    expect(selected, isNonNegative);

    await gesture.moveTo(box.bottomRight + const Offset(24, 24));
    await tester.pump();
    expect(find.byKey(const Key('chart_scrub_marker')), findsNothing);
    expect(selected, isNull);
  });

  testWidgets('equal-but-new point lists keep the marker while hovering', (
    tester,
  ) async {
    var selected = -1;
    final times = [
      DateTime.utc(2026, 8, 1),
      DateTime.utc(2026, 8, 2),
      DateTime.utc(2026, 8, 3),
      DateTime.utc(2026, 8, 4),
    ];
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      chart(
        series: List.of(points),
        times: times,
        onScrub: (index) => selected = index ?? -1,
      ),
    );
    await gesture.moveTo(tester.getCenter(find.byType(PriceChart)));
    await tester.pump();
    expect(find.byKey(const Key('chart_scrub_marker')), findsOneWidget);
    expect(selected, isNonNegative);

    await tester.pumpWidget(
      chart(
        series: List.of(points),
        times: List.of(times),
        onScrub: (index) => selected = index ?? -1,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('chart_scrub_marker')), findsOneWidget);
  });
}
