import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_planner/features/auth/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen has a rounded Get Started button on the last page', (WidgetTester tester) async {
    // Build the OnboardingScreen
    await tester.pumpWidget(const MaterialApp(
      home: OnboardingScreen(),
    ));

    // Verify initial state
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);

    // Navigate to the last page (page 2, index starting at 0)
    // We can use jumpToPage(2) by finding the controller or just swiping
    // But since it's a private controller in the state, swiping is better or we can use the NEXT button
    
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    // Now 'Get Started' should be visible
    expect(find.text('Get Started'), findsOneWidget);

    // Verify button styling and shape
    final textButtonFinder = find.widgetWithText(TextButton, 'Get Started');
    expect(textButtonFinder, findsOneWidget);

    final TextButton button = tester.widget(textButtonFinder);
    final OutlinedBorder? shape = button.style?.shape?.resolve({});
    
    expect(shape, isA<RoundedRectangleBorder>());
    final roundedShape = shape as RoundedRectangleBorder;
    expect(roundedShape.borderRadius, BorderRadius.circular(30));
  });
}
