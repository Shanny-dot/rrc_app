import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/core_widgets.dart';
import '../../widgets/loading.dart';
import '../../widgets/ui_kit.dart';

/// For members who skipped a code at sign-up, signed up with Google/Apple (no mobile yet), or
/// changed their mobile: verify the mobile and email here. The welcome points are added once
/// both are verified. Pops with true when anything changed.
class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({Key? key}) : super(key: key);

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final ApiService _api = ApiService();
  final _mobileController = TextEditingController();
  final _codeControllers = {'sms': TextEditingController(), 'email': TextEditingController()};
  final Set<String> _codeSent = {};
  String? _busy; // 'sms' or 'email' while a request is running
  bool _loading = true;
  bool _changed = false;
  Map<String, dynamic> _me = {};

  Map<String, dynamic> get _status => _me['verification'] is Map ? Map<String, dynamic>.from(_me['verification']) : {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    for (final c in _codeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _api.getMe();
    if (!mounted) return;
    setState(() {
      if (res['success']) _me = Map<String, dynamic>.from(res['data']);
      _loading = false;
    });
  }

  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _send(String channel) async {
    setState(() => _busy = channel);
    if (channel == 'sms' && (_me['mobile'] ?? '').toString().trim().isEmpty) {
      final mobile = _mobileController.text.trim();
      if (mobile.isEmpty) {
        setState(() => _busy = null);
        _say('Please enter your mobile number.');
        return;
      }
      final saved = await _api.updateProfile({'mobile': mobile});
      if (!saved['success']) {
        if (mounted) setState(() => _busy = null);
        _say(saved['error'].toString());
        return;
      }
      _me['mobile'] = mobile;
      _changed = true;
    }
    final res = await _api.sendMyCode(channel);
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (res['success']) _codeSent.add(channel);
    });
    _say(res['success'] ? (channel == 'sms' ? 'Code sent to your mobile.' : 'Code sent to your email.') : res['error'].toString());
  }

  Future<void> _check(String channel) async {
    final code = _codeControllers[channel]!.text.trim();
    if (code.isEmpty) {
      _say('Please enter the 6-digit code.');
      return;
    }
    setState(() => _busy = channel);
    final res = await _api.checkMyCode(channel, code);
    if (!mounted) return;
    setState(() => _busy = null);
    if (!res['success']) {
      _say(res['error'].toString());
      return;
    }
    _changed = true;
    final points = Fmt.toInt(res['data']['points_added']);
    await _load();
    if (!mounted) return;
    if (res['data']['verified'] == true) {
      _say(points > 0 ? 'All done! ${Fmt.number(points)} bonus points have been added.' : 'Your account is verified.');
      Navigator.pop(context, true);
    } else {
      _say(channel == 'sms' ? 'Mobile verified.' : 'Email verified.');
    }
  }

  Widget _step(String channel, String title, String? sentTo, bool verified) {
    final needsMobile = channel == 'sms' && (sentTo ?? '').trim().isEmpty;
    final busy = _busy == channel;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: verified ? AppColors.primaryGold.withValues(alpha: 0.5) : UiColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(verified ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: verified ? AppColors.primaryGold : AppColors.textSecondary, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTextStyles.labelLarge)),
          if (verified) Text('Verified', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold)),
        ]),
        if (!needsMobile && sentTo != null) ...[
          const SizedBox(height: 6),
          Padding(padding: const EdgeInsets.only(left: 32), child: Text(sentTo, style: AppTextStyles.labelSmall)),
        ],
        if (!verified) ...[
          const SizedBox(height: 14),
          if (needsMobile) ...[
            DarkTextField(hint: 'Mobile number, e.g. 0412 345 678', keyboardType: TextInputType.phone, controller: _mobileController),
            const SizedBox(height: 10),
          ],
          if (_codeSent.contains(channel)) ...[
            DarkTextField(
              hint: 'Enter 6-digit code',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              controller: _codeControllers[channel],
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlineAction(text: 'Resend', onPressed: busy ? null : () => _send(channel))),
              const SizedBox(width: 12),
              Expanded(child: FilledAction(text: busy ? 'Checking…' : 'Confirm', onPressed: busy ? null : () => _check(channel))),
            ]),
            if (channel == 'email') ...[
              const SizedBox(height: 8),
              Text('Can\'t see the email? Check your Spam or Junk folder.', style: AppTextStyles.labelSmall),
            ],
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledAction(
                text: busy ? 'Sending…' : (needsMobile ? 'Save & send code' : 'Send code'),
                onPressed: busy ? null : () => _send(channel),
              ),
            ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _status['pending_welcome_points'];
    final pendingPoints = pending is num ? pending.toInt() : 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Verify your account')),
        body: SafeArea(
          child: _loading
              ? const FriendlyLoader()
              : ListView(
                  padding: const EdgeInsets.all(AppDimens.pageMargin),
                  children: [
                    Text(
                      pendingPoints > 0
                          ? 'Verify your mobile and email to finish setting up your account and collect your '
                              '${Fmt.number(pendingPoints)} bonus points.'
                          : 'Verify your mobile and email to finish setting up your account.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    _step('sms', 'Mobile number', _me['mobile']?.toString(), _status['mobile_verified'] == true),
                    _step('email', 'Email address', _me['email']?.toString(), _status['email_verified'] == true),
                  ],
                ),
        ),
      ),
    );
  }
}
