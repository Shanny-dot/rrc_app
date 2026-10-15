import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading.dart';
import '../../widgets/ui_kit.dart';
import 'welcome_tour.dart';

/// Contact details and help content, edited by staff on the admin "Help & Contact" page.
class ProgramContact {
  final String name;
  final String phone;
  final String email;
  final String bookingUrl;
  final String hours;
  final String termsUrl;
  final String privacyUrl;
  final List<Map<String, String>> faq;

  const ProgramContact({
    this.name = 'Your Reliance broker',
    this.phone = '',
    this.email = '',
    this.bookingUrl = '',
    this.hours = '',
    this.termsUrl = '',
    this.privacyUrl = '',
    this.faq = const [],
  });

  bool get hasAnyContact => phone.isNotEmpty || email.isNotEmpty || bookingUrl.isNotEmpty;

  static ProgramContact? _cached;

  /// Loads once per app session; [refresh] forces a reload (e.g. pull-to-refresh on Help).
  static Future<ProgramContact> load({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;
    final c = await ApiService().getAppContent();
    if (c.isEmpty) return _cached ?? const ProgramContact();
    List<Map<String, String>> faq = [];
    try {
      faq = (jsonDecode(c['help_faq'] ?? '[]') as List)
          .whereType<Map>()
          .map((i) => {'q': (i['q'] ?? '').toString(), 'a': (i['a'] ?? '').toString()})
          .where((i) => i['q']!.isNotEmpty)
          .toList();
    } catch (_) {}
    String v(String key) => (c[key] ?? '').trim();
    return _cached = ProgramContact(
      name: v('contact_name').isEmpty ? 'Your Reliance broker' : v('contact_name'),
      phone: v('contact_phone'),
      email: v('contact_email'),
      bookingUrl: v('contact_booking_url'),
      hours: v('contact_hours'),
      termsUrl: v('terms_url'),
      privacyUrl: v('privacy_url'),
      faq: faq,
    );
  }
}

Future<void> _open(BuildContext context, Uri uri) async {
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) showToast(context, 'Couldn\'t open that on this device.', error: true);
}

/// Call / Email / Book a time buttons. Buttons without details set by staff are hidden.
class BrokerActions extends StatelessWidget {
  final ProgramContact info;
  final String emailSubject;
  const BrokerActions({Key? key, required this.info, this.emailSubject = 'Question from the Reliance Rewards app'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (info.phone.isNotEmpty)
        OutlineAction(text: 'Call', icon: Icons.call_outlined, color: AppColors.primaryGold,
            onPressed: () => _open(context, Uri(scheme: 'tel', path: info.phone.replaceAll(RegExp(r'[^\d+]'), '')))),
      if (info.email.isNotEmpty)
        OutlineAction(text: 'Email', icon: Icons.mail_outline_rounded, color: AppColors.primaryGold,
            onPressed: () => _open(context, Uri(scheme: 'mailto', path: info.email, query: 'subject=${Uri.encodeComponent(emailSubject)}'))),
      if (info.bookingUrl.isNotEmpty)
        OutlineAction(text: 'Book a time', icon: Icons.event_available_outlined, color: AppColors.primaryGold,
            onPressed: () => _open(context, Uri.parse(info.bookingUrl))),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      for (int i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: buttons[i]),
      ],
    ]);
  }
}

/// "Talk to my broker" card for Home. Hidden until staff add at least one contact method.
class BrokerCard extends StatelessWidget {
  final ProgramContact info;
  const BrokerCard({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!info.hasAnyContact) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: UiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: UiColors.goldBg, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.primaryGold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Talk to my broker', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(info.hours.isNotEmpty ? '${info.name} · ${info.hours}' : info.name, style: AppTextStyles.labelSmall),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          BrokerActions(info: info),
        ],
      ),
    );
  }
}

// ----------------- Help & contact ----------------- //
class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  ProgramContact? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final info = await ProgramContact.load(refresh: refresh);
    if (mounted) setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & contact')),
      body: info == null
          ? const FriendlyLoader(message: 'Loading help…')
          : RefreshIndicator(
              color: AppColors.primaryGold,
              onRefresh: () => _load(refresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 8, AppDimens.pageMargin, 32),
                children: [
                  const SectionLabel('Common questions'),
                  if (info.faq.isEmpty)
                    Text('No questions yet — contact us below and we\'ll help.', style: AppTextStyles.bodyMedium)
                  else
                    ...info.faq.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              iconColor: AppColors.primaryGold,
                              collapsedIconColor: AppColors.textSecondary,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              expandedCrossAxisAlignment: CrossAxisAlignment.start,
                              title: Text(item['q']!, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                              children: [Text(item['a']!, style: AppTextStyles.bodyMedium.copyWith(height: 1.5))],
                            ),
                          ),
                        )),
                  const SizedBox(height: 18),
                  const SectionLabel('Contact us'),
                  if (info.hasAnyContact) ...[
                    if (info.hours.isNotEmpty) ...[
                      Text(info.hours, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                    ],
                    BrokerActions(info: info),
                  ] else
                    Text('Contact details are coming soon.', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 18),
                  const SectionLabel('About the program'),
                  _linkRow(Icons.play_circle_outline_rounded, 'Replay the welcome tour',
                      () => Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => const WelcomeTourScreen()))),
                  if (info.termsUrl.isNotEmpty)
                    _linkRow(Icons.description_outlined, 'Program terms', () => _open(context, Uri.parse(info.termsUrl))),
                  if (info.privacyUrl.isNotEmpty)
                    _linkRow(Icons.privacy_tip_outlined, 'Privacy policy', () => _open(context, Uri.parse(info.privacyUrl))),
                ],
              ),
            ),
    );
  }

  Widget _linkRow(IconData icon, String text, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
            leading: Icon(icon, color: AppColors.primaryGold),
            title: Text(text, style: AppTextStyles.labelLarge),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: onTap,
          ),
        ),
      );
}
