import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rrc_app/screens/redesign/help_screen.dart';
import 'package:rrc_app/screens/redesign/welcome_tour.dart';
import 'package:rrc_app/services/invite_code.dart';
import 'package:rrc_app/widgets/loading.dart';

// Widget tests for the 3.2 member tools: loading states, welcome tour and broker buttons.
Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // Tests run offline; use the default font instead of downloading Poppins.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('loading message explains a slow server instead of spinning silently', (tester) async {
    await tester.pumpWidget(_app(const FriendlyLoader(message: 'Loading rewards…', layout: SkeletonLayout.cards)));
    expect(find.text('Loading rewards…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('up to 30 seconds'), findsOneWidget);
  });

  testWidgets('error view retries', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_app(LoadErrorView(onRetry: () => retried++)));
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('welcome tour pages through to Get started', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomeTourScreen())),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Reliiance Rewards'), findsOneWidget);
    for (final title in ['Earn points', 'Refer in a tap', 'Redeem rewards']) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('broker card: Book a time always, Call/Email once staff add them', (tester) async {
    await tester.pumpWidget(_app(const BrokerCard(info: ProgramContact())));
    expect(find.text('Contact us'), findsOneWidget); // title staff can change on the admin website
    expect(find.text('Book a time'), findsOneWidget);
    expect(find.text('Call'), findsNothing);

    await tester.pumpWidget(_app(const BrokerCard(info: ProgramContact(phone: '02 9000 0000'))));
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Email'), findsNothing);

    // No booking link set: Book a time opens the in-app request sheet.
    await tester.tap(find.text('Book a time'));
    await tester.pumpAndSettle();
    expect(find.text('Request this time'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
  });

  test('invite code from links and Google Play referrer', () {
    expect(InviteCode.codeFromUri(Uri.parse('reliancerewards://join/manoj123')), 'MANOJ123');
    expect(InviteCode.codeFromUri(Uri.parse('https://rrc-admin.vercel.app/join/ABCD1234')), 'ABCD1234');
    expect(InviteCode.codeFromUri(Uri.parse('reliancerewards://join/bad!code')), isNull);
    expect(InviteCode.codeFromReferrer('rrc_code%3DMANOJ123'), 'MANOJ123');
    expect(InviteCode.codeFromReferrer('rrc_code=ABCD1234&utm_source=x'), 'ABCD1234');
    expect(InviteCode.codeFromReferrer('utm_source=google-play&utm_medium=organic'), isNull);
  });
}
