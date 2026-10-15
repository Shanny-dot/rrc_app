import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_flow.dart';
import 'services/api_service.dart';
import 'services/invite_code.dart';

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
        content: Text('You\'re already a member — invite codes are for friends joining Reliance Rewards.'),
      ));
    } else {
      _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const QuickSignUpScreen()));
    }
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
