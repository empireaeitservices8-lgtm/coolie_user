import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:cooli/features/dashboard/view/home_view.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';
import 'package:cooli/features/ride/view/ride_booking_view.dart';
import 'package:cooli/features/ride/view/ride_completed_view.dart';
import 'package:cooli/features/ride/view/ride_selection_view.dart';
import 'package:cooli/features/ride/view/ride_tracking_view.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/providers/language_provider.dart';
import 'package:cooli/providers/theme_provider.dart';
import 'package:cooli/utils/routes.dart';

Widget _buildTestHarness({String initialRoute = MainNavigationView.routeName}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => RideViewModel()),
    ],
    child: MaterialApp(
      initialRoute: initialRoute,
      routes: appRoutes(),
      onGenerateRoute: onAppGenerateRoute(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Full Uber-style rider flow from Home to Ride Completed',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildTestHarness());
    await tester.pump();

    // 1. Home -> Tap Rides card -> opens RideBookingView ("Where to?" Uber flow)
    expect(find.byType(HomeView), findsOneWidget);
    await tester.tap(find.text('Rides'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(RideBookingView), findsOneWidget);
    expect(find.text('From Current Location'), findsOneWidget);
    expect(find.text('Where to?'), findsOneWidget);

    // 2. Tap quick destination chip "Work" -> navigates to RideSelectionView
    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(RideSelectionView), findsOneWidget);
    expect(find.text('Choose a ride'), findsOneWidget);
    expect(find.textContaining('Current Location  →  Work'), findsOneWidget);

    // 3. Select "Cooli Auto"
    await tester.tap(find.text('Cooli Auto'));
    await tester.pump();

    // 4. Open payment options sheet, apply promo COOLI20, and choose Cash
    await tester.tap(find.text('UPI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Payment options'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'COOLI20');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.textContaining('Applied COOLI20!'), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Cash'), findsOneWidget);

    // 5. Tap "Choose Cooli Auto ..." -> opens Confirm pickup spot sheet
    await tester.tap(find.textContaining('Choose Cooli Auto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Confirm your pickup spot'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Near main gate');
    await tester.tap(find.text('Confirm Pickup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 6. RideTrackingView: Searching Driver -> Match Driver -> Driver En Route -> Arrived -> In Progress -> Complete
    expect(find.byType(RideTrackingView), findsOneWidget);
    expect(find.text('Finding your Cooli Auto...'), findsOneWidget);

    await tester.tap(find.text('Match Driver Now'));
    await tester.pump();

    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Suresh Babu'), findsOneWidget);
    expect(find.text('KL 07 CD 4812'), findsOneWidget);
    expect(find.text('4219'), findsOneWidget);

    // Open in-app driver chat and send quick reply
    await tester.tap(find.text('Message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text("I'm at the pickup point"));
    await tester.pump();
    expect(find.text('Got it, thanks! See you shortly.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Advance tracking lifecycle
    await tester.tap(find.text('Simulate Driver Arrived'));
    await tester.pump();
    expect(find.text('Driver arrived'), findsOneWidget);
    expect(find.text('Suresh is at pickup'), findsOneWidget);

    await tester.tap(find.text('Start Trip (Verify PIN 4219)'));
    await tester.pump();
    expect(find.text('Trip in progress'), findsOneWidget);
    expect(find.text('Heading to Work'), findsOneWidget);

    await tester.tap(find.text('Complete Ride'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 7. RideCompletedView: dynamic route, payment method, tip, receipt & submit
    expect(find.byType(RideCompletedView), findsOneWidget);
    expect(find.text('Ride Completed!'), findsOneWidget);
    expect(find.text('Current Location → Work'), findsOneWidget);
    expect(find.text('Paid via Cash'), findsOneWidget);

    // Add ₹50 tip and check total updates (Auto 11.2km: base 30 + 11.2*11 + 10 - 20 = 143.2 -> 145 + 50 = 195)
    expect(find.text('₹145'), findsOneWidget);
    await tester.tap(find.text('₹50'));
    await tester.pump();
    expect(find.text('₹195'), findsOneWidget);

    // Submit Rating returns to HomeView
    await tester.tap(find.text('Submit Rating'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('Plan your ride sheet supports search, swap, and custom destination',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildTestHarness(initialRoute: RideBookingView.routeName));
    await tester.pump();

    // Open Plan your ride sheet via "Where to?" search bar
    await tester.tap(find.byKey(const Key('ride_where_to_bar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Plan your ride'), findsOneWidget);

    // Search for "Lulu" and select Lulu International Mall
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.last, 'Lulu');
    await tester.pump();

    await tester.tap(find.text('Lulu International Mall'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(RideSelectionView), findsOneWidget);
    expect(find.textContaining('Lulu International Mall'), findsWidgets);

    // Tap route header pill to re-open Plan your ride and test swap
    await tester.tap(find.textContaining('Current Location  →  Lulu International Mall'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Plan your ride'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await tester.pump();

    expect(find.text('Lulu International Mall'), findsWidgets);
  });
}
