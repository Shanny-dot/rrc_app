import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading.dart';
import '../../widgets/ui_kit.dart';
import 'feedback_screen.dart';
import 'home_tab.dart' show TiersScreen;
import 'welcome_tour.dart';

/// Contact details and help content, edited by staff on the admin "Help & Contact" page.
class ProgramContact {
  final String cardTitle;
  final String name;
  final String phone;
  final String email;
  final String bookingUrl;
  final String hours;
  final String termsUrl;
  final String privacyUrl;
  final List<Map<String, String>> faq;

  const ProgramContact({
    this.cardTitle = 'Contact us',
    this.name = 'Your Reliiance broker',
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
      cardTitle: v('contact_card_title').isEmpty ? 'Contact us' : v('contact_card_title'),
      name: v('contact_name').isEmpty ? 'Your Reliiance broker' : v('contact_name'),
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

/// Call / Email / Book a time buttons. Call and Email appear once staff add those details;
/// Book a time opens the booking link if one is set, otherwise the in-app request sheet.
class BrokerActions extends StatelessWidget {
  final ProgramContact info;
  final String emailSubject;
  const BrokerActions({Key? key, required this.info, this.emailSubject = 'Question from the Reliiance Rewards app'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (info.phone.isNotEmpty)
        OutlineAction(text: 'Call', icon: Icons.call_outlined, color: AppColors.primaryGold,
            onPressed: () => _open(context, Uri(scheme: 'tel', path: info.phone.replaceAll(RegExp(r'[^\d+]'), '')))),
      if (info.email.isNotEmpty)
        OutlineAction(text: 'Email', icon: Icons.mail_outline_rounded, color: AppColors.primaryGold,
            onPressed: () => _open(context, Uri(scheme: 'mailto', path: info.email, query: 'subject=${Uri.encodeComponent(emailSubject)}'))),
      OutlineAction(text: 'Book a time', icon: Icons.event_available_outlined, color: AppColors.primaryGold,
          onPressed: () => info.bookingUrl.isNotEmpty
              ? _open(context, Uri.parse(info.bookingUrl))
              : showBookTimeSheet(context, info)),
    ];
    return Row(children: [
      for (int i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: buttons[i]),
      ],
    ]);
  }
}

/// "Contact us" card for Home (title edited on the admin Help & Contact page).
class BrokerCard extends StatelessWidget {
  final ProgramContact info;
  const BrokerCard({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Text(info.cardTitle, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
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
                  SectionLabel(info.cardTitle),
                  if (info.hours.isNotEmpty) ...[
                    Text('${info.name} · ${info.hours}', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                  ],
                  BrokerActions(info: info),
                  const SizedBox(height: 10),
                  _linkRow(Icons.rate_review_outlined, 'Send feedback',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
                  const SizedBox(height: 18),
                  const SectionLabel('About the program'),
                  _linkRow(Icons.star_border_rounded, 'What do tiers give me?',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TiersScreen()))),
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

// ----------------- Book a time (in-app request) ----------------- //
Future<void> showBookTimeSheet(BuildContext context, ProgramContact info) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _BookTimeSheet(info: info),
  );
}

class _BookTimeSheet extends StatefulWidget {
  final ProgramContact info;
  const _BookTimeSheet({required this.info});

  @override
  State<_BookTimeSheet> createState() => _BookTimeSheetState();
}

class _BookTimeSheetState extends State<_BookTimeSheet> {
  static const _times = {'morning': 'Morning', 'afternoon': 'Afternoon', 'evening': 'Evening', 'anytime': 'Any time'};
  late final List<DateTime> _days = _nextWeekdays(10);
  late DateTime _day = _days.first;
  String _time = 'morning';
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  static List<DateTime> _nextWeekdays(int count) {
    final out = <DateTime>[];
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    while (out.length < count) {
      if (d.weekday <= DateTime.friday) out.add(d);
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final res = await ApiService().requestBroker(
      kind: 'call',
      preferredDate: Fmt.isoDate(_day),
      preferredTime: _time,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pop(context);
      showToast(context, 'Request sent. ${widget.info.name} will be in touch to confirm a time.');
    } else {
      setState(() {
        _sending = false;
        _error = (res['error'] ?? "Couldn't send your request").toString();
      });
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: AppColors.inputFill,
        selectedColor: UiColors.goldBg,
        side: BorderSide(color: selected ? AppColors.primaryGold : UiColors.border),
        labelStyle: TextStyle(color: selected ? AppColors.primaryGold : AppColors.textPrimary, fontWeight: FontWeight.w600),
      );

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static String _dayLabel(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppDimens.pageMargin, 20, AppDimens.pageMargin, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Book a time', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('Choose a day and time that suits you. ${widget.info.name} will call to confirm.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 18),
            Text('Day', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _chip(_dayLabel(_days[i]), _days[i] == _day, () => setState(() => _day = _days[i])),
              ),
            ),
            const SizedBox(height: 16),
            Text('Time', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _times.entries.map((t) => _chip(t.value, _time == t.key, () => setState(() => _time = t.key))).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'What would you like to talk about? (optional)',
                hintStyle: AppTextStyles.bodyMedium,
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusInput), borderSide: BorderSide.none),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledAction(text: _sending ? 'Sending…' : 'Request this time', onPressed: _sending ? null : _send),
            ),
          ],
        ),
      ),
    );
  }
}
