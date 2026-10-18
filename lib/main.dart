import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_flow.dart';
import 'screens/dashboard_screens.dart' show openAlert;
import 'services/api_service.dart';
import 'services/invite_code.dart';
import 'services/push_alerts.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Personal invite links (reliancerewards://join/CODE) — read before the splash decides
  // whether to show sign-up. Never hold up launch for long.
  await InviteCode.init().timeout(const Duration(seconds: 3), onTimeout: () {});
  InviteCode.onLinkWhileRunning = (code) async {
    if (await ApiService().isLoggedIn()) {
      _messengerKey.currentState?.showSnackBar(const SnackBar(
        content: Text('You\'re already a member — invite codes are for friends joining Reliiance Rewards.'),
      ));
    } else {
      _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const QuickSignUpScreen()));
    }
  };
  // Phone alerts: a tap opens the matching screen; alerts that arrive while the app is open
  // show as a banner.
  await PushAlerts.init().timeout(const Duration(seconds: 5), onTimeout: () {});
  PushAlerts.onOpen = (data) {
    final context = _navigatorKey.currentContext;
    if (context != null) openAlert(context, data);
  };
  PushAlerts.onForeground = (title, body, data) {
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(body.isEmpty ? title : '$title\n$body'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'View', onPressed: () {
        final context = _navigatorKey.currentContext;
        if (context != null) openAlert(context, data);
      }),
    ));
  };
  runApp(const RRCApp());
}

class RRCApp extends StatelessWidget {
  const RRCApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RRC - Luxury Rewards',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
