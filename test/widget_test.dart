import 'package:flutter_test/flutter_test.dart';
import 'package:new_youtube/main.dart';

void main() {
  testWidgets('AuraTube smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraTubeApp());
    expect(find.byType(AuraTubeApp), findsOneWidget);
  });
}
