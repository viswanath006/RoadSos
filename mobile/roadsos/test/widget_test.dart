import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roadsos/main.dart';

void main() {
  testWidgets('Home screen shows RoadSoS branding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RoadSosApp()));
    expect(find.text('RoadSoS'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
  });
}
