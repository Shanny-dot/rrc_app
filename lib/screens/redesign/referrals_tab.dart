import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/core_widgets.dart';
import '../../widgets/ui_kit.dart';
import '../dashboard_screens.dart' show ReferFormScreen;
import '../import_contacts_screen.dart';
import '../../widgets/loading.dart';

/// The three stages shown on each referral card.
const kReferralSteps = ['Invited', 'Pending /\nsigned up', 'Points added\nto account'];

/// How many steps are complete for a backend status.
int completedSteps(String status) {
  switch (status) {
    case 'registered':
    case 'contacted': // older, more detailed stages count as the middle one
    case 'loan_in_progress':
    case 'settled':
      return 2;
    case 'rewarded':
      return 3;
    default: // pending, invited, closed
      return 1;
  }
}

String referralStatusLabel(String status) {
  switch (status) {
    case 'registered':
      return 'Signed up';
    case 'contacted':
    case 'loan_in_progress':
    case 'settled':
      return 'Pending';
    case 'rewarded':
      return 'Points added';
    case 'closed':
      return 'Not proceeding';
    default:
      return 'Invited';
  }
}

String _channelText(dynamic r) {
  switch ((r['channel'] ?? '').toString()) {
    case 'sms':
      return 'Invited by SMS';
    case 'whatsapp':
      return 'Invited by WhatsApp';
    case 'email':
      return 'Invited by email';
    case 'share':
      return 'Invited by message';
    case 'code':
      return 'Joined with your code';
    default:
      return r['status'] == 'registered' ? 'Joined with your code' : 'Referred';
  }
}

// ----------------- Referrals ----------------- //
class ReferralsTab extends StatefulWidget {
  const ReferralsTab({Key? key}) : super(key: key);

  @override
  State<ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<ReferralsTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _referrals = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_referrals.isEmpty) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([_api.getReferrals(), _api.getReferralSummary()]);
      if (results[0]['success'] && results[0]['data'] is List) _referrals = results[0]['data'];
      if (results[1]['success'] && results[1]['data'] is Map) _summary = Map<String, dynamic>.from(results[1]['data']);
    } catch (e) {
      debugPrint('Referrals load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startInvite(InviteChannel channel) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => InviteFriendSheet(channel: channel, summary: _summary),
    );
    if (sent == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final earned = Fmt.toInt(_summary['points_earned']);
    final perReferral = Fmt.toInt(_summary['points_per_referral']);
    final rule = perReferral > 0
        ? 'Earn ${Fmt.number(perReferral)} points for every friend you refer to Reliiance.'
        : 'Earn points for every friend you refer to Reliiance.';

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const FriendlyLoader(message: 'Loading your referrals…')
            : RefreshIndicator(
                color: AppColors.primaryGold,
                backgroundColor: AppColors.surfaceCard,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 16, AppDimens.pageMargin, 24),
                  children: [
                    Text('Referrals', style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: UiColors.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Points earned from referrals', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 4),
                        Text(Fmt.pts(earned), style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 38)),
                        const SizedBox(height: 6),
                        Text(rule, style: AppTextStyles.bodyMedium),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    Text('Invite a friend', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: FilledAction(text: 'SMS / WhatsApp', icon: Icons.chat_bubble_outline_rounded, onPressed: () => _startInvite(InviteChannel.message)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlineAction(text: 'Email', icon: Icons.mail_outline_rounded, color: AppColors.primaryGold, onPressed: () => _startInvite(InviteChannel.email)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    // Two equal halves, so each link sits centred under the button above it.
                    Row(children: [
                      Expanded(
                        child: _link('Enter details manually', () async {
                          final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferFormScreen()));
                          if (ok == true) _load();
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _link('Import contacts', () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportContactsScreen()));
                          _load();
                        }),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your referrals', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                        if (_referrals.isNotEmpty)
                          Text('${_referrals.length} friend${_referrals.length == 1 ? '' : 's'}', style: AppTextStyles.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_referrals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text('No referrals yet.\nInvite a friend and track their progress here.',
                              textAlign: TextAlign.center, style: AppTextStyles.labelMedium),
                        ),
                      )
                    else
                      ..._referrals.map((r) => ReferralCard(referral: r)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _link(String text, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, decoration: TextDecoration.underline)),
        ),
      );
}

/// A referral with its status chip and five-stage tracker.
class ReferralCard extends StatelessWidget {
  final dynamic referral;
  const ReferralCard({Key? key, required this.referral}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = (referral['status'] ?? 'invited').toString();
    final closed = status == 'closed';
    final done = completedSteps(status);
    final subtitle = '${_channelText(referral)} · ${Fmt.date(Fmt.parse(referral['created_at']))}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((referral['referred_name'] ?? 'Friend').toString(), style: AppTextStyles.h3.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ]),
            ),
            StatusChip(referralStatusLabel(status)),
          ]),
          const SizedBox(height: 16),
          Opacity(opacity: closed ? 0.45 : 1, child: _Stepper(done: done)),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int done; // number of completed steps (1–3)
  const _Stepper({required this.done});

  @override
  Widget build(BuildContext context) {
    const dot = 22.0;
    final current = done < kReferralSteps.length ? done : -1; // the step in progress
    return Column(children: [
      SizedBox(
        height: dot,
        child: Row(children: [
          for (int i = 0; i < kReferralSteps.length; i++) ...[
            if (i > 0)
              Expanded(child: Container(height: 3, color: i <= done ? AppColors.primaryGold : AppColors.inputFill)),
            _dot(i < done ? _DotState.done : (i == current ? _DotState.current : _DotState.todo), dot),
          ],
        ]),
      ),
      const SizedBox(height: 6),
      // Labels centred under their dots (positions match the dot row above).
      LayoutBuilder(builder: (context, c) {
        const labelW = 96.0;
        final w = c.maxWidth;
        final step = (w - dot) / (kReferralSteps.length - 1);
        return SizedBox(
          height: 30,
          child: Stack(children: [
            for (int i = 0; i < kReferralSteps.length; i++)
              Positioned(
                left: (dot / 2 + i * step - labelW / 2).clamp(0.0, w - labelW).toDouble(),
                width: labelW,
                child: Text(
                  kReferralSteps[i],
                  textAlign: i == 0 ? TextAlign.left : (i == kReferralSteps.length - 1 ? TextAlign.right : TextAlign.center),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: i < done || i == current ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: i < done || i == current ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
          ]),
        );
      }),
    ]);
  }

  Widget _dot(_DotState s, double size) {
    switch (s) {
      case _DotState.done:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 15, color: AppColors.backgroundBase),
        );
      case _DotState.current:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGold, width: 3),
          ),
        );
      case _DotState.todo:
        return Container(
          width: size - 4,
          height: size - 4,
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: AppColors.inputFill, shape: BoxShape.circle),
        );
    }
  }
}

enum _DotState { done, current, todo }

enum InviteChannel { message, email }

/// Collects the friend's details, records the referral, then opens the phone's share sheet
/// (SMS / WhatsApp) or mail app with a ready-written invitation from the member.
class InviteFriendSheet extends StatefulWidget {
  final InviteChannel channel;
  final Map<String, dynamic> summary;
  const InviteFriendSheet({Key? key, required this.channel, required this.summary}) : super(key: key);

  @override
  State<InviteFriendSheet> createState() => _InviteFriendSheetState();
}

class _InviteFriendSheetState extends State<InviteFriendSheet> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  bool _consent = false;
  bool _sending = false;
  String? _error;

  bool get _isEmail => widget.channel == InviteChannel.email;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  String _message(String friendName) {
    final first = friendName.trim().split(' ').first;
    final code = (widget.summary['referral_code'] ?? '').toString();
    final link = (widget.summary['invite_link'] ?? '').toString();
    final buf = StringBuffer('Hi $first, I\'m a member of Reliiance Rewards and think you\'d enjoy it too');
    if (code.isNotEmpty) buf.write(' — join with my referral code $code');
    buf.write('.');
    if (link.isNotEmpty) buf.write(' $link');
    return buf.toString();
  }

  Future<void> _continue() async {
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    final mobile = contact.replaceAll(RegExp(r'[\s\-()]'), '');
    String? problem;
    if (name.isEmpty) {
      problem = 'Please enter your friend\'s name.';
    } else if (_isEmail && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(contact)) {
      problem = 'Please enter a valid email address.';
    } else if (!_isEmail && !RegExp(r'^(?:\+?61|0)?4\d{8}$').hasMatch(mobile)) {
      problem = 'Please enter a valid Australian mobile number.';
    } else if (!_consent) {
      problem = 'Please confirm your friend is happy to be contacted.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    final res = await ApiService().submitReferral({
      'referred_name': name,
      if (_isEmail) 'referred_email': contact else 'referred_mobile': mobile,
      'channel': _isEmail ? 'email' : 'share',
      'consent_given': true,
    });
    if (!mounted) return;
    if (!res['success']) {
      setState(() {
        _sending = false;
        _error = (res['error'] ?? 'Could not save the referral').toString();
      });
      return;
    }

    // Email invitations are sent by us from no-reply. If that isn't possible right now,
    // the member's own mail app opens with the message ready instead.
    final emailedByUs = _isEmail && res['data'] is Map && res['data']['invite_emailed'] == true;
    final message = _message(name);
    try {
      if (_isEmail && !emailedByUs) {
        final uri = Uri.parse('mailto:$contact?subject=${Uri.encodeComponent('An invitation to Reliiance Rewards')}'
            '&body=${Uri.encodeComponent(message)}');
        await launchUrl(uri);
      } else if (!_isEmail) {
        await SharePlus.instance.share(ShareParams(text: message, subject: 'An invitation to Reliiance Rewards'));
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    showToast(context, emailedByUs
        ? 'Invitation emailed to $name. We\'ve added them to your referrals.'
        : 'Thanks! We\'ve added $name to your referrals.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(_isEmail ? 'Invite by email' : 'Invite by SMS or WhatsApp', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            _isEmail
                ? 'We\'ll email your friend an invitation with your referral code.'
                : 'We\'ll open your phone\'s share options so you can send it by SMS, WhatsApp or another app.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 18),
          LabeledField(label: 'Friend\'s name', child: DarkTextField(hint: 'Full name', controller: _name)),
          const SizedBox(height: 12),
          LabeledField(
            label: _isEmail ? 'Email' : 'Mobile',
            child: DarkTextField(
              hint: _isEmail ? 'name@example.com' : '04XX XXX XXX',
              controller: _contact,
              keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _consent = !_consent),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                activeColor: AppColors.primaryGold,
                checkColor: AppColors.backgroundBase,
                side: const BorderSide(color: AppColors.textSecondary),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('My friend is happy to be contacted by Reliiance.', style: AppTextStyles.bodyMedium),
                ),
              ),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _sending
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : FilledAction(text: _isEmail ? 'Send invitation' : 'Continue to share', onPressed: _continue),
          ),
        ],
      ),
    );
  }
}
