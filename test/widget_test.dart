import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swifty_proteins_42/main.dart';

void main() {
  testWidgets('App loads with welcome message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SwiftyProteinsApp());

    // Verify that our app loads with the welcome message.
    expect(find.text('Welcome to Swifty Proteins!'), findsOneWidget);
    expect(find.text('Your app skeleton is ready.'), findsOneWidget);
    expect(find.text('Swifty Proteins'), findsOneWidget);
  });
}
