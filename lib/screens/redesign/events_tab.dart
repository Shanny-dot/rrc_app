import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/core_widgets.dart';
import '../../widgets/ui_kit.dart';
import '../dashboard_screens.dart' show QRScannerScreen;
import '../../widgets/loading.dart';

// ----------------- Shared event helpers (list and detail screen) ----------------- //

/// "50" or, when staff set an "up to" amount on the admin website, "50–100".
String eventPointsText(dynamic e, String key) {
  final min = Fmt.toInt(e[key]);
  final max = Fmt.toInt(e['${key}_max']);
  return max > min ? '${Fmt.number(min)}–${Fmt.number(max)}' : Fmt.number(min);
}

bool _hasPoints(dynamic e, String key) => Fmt.toInt(e[key]) > 0 || Fmt.toInt(e['${key}_max']) > 0;

IconData eventIcon(dynamic e) {
  final text = '${e['category'] ?? ''} ${e['title'] ?? ''} ${e['location'] ?? ''}'.toLowerCase();
  if (text.contains('online') || text.contains('webinar') || text.contains('virtual')) return Icons.desktop_windows_outlined;
  if (text.contains('home') || text.contains('buyer') || text.contains('property') || text.contains('real estate')) return Icons.home_outlined;
  if (text.contains('dinner') || text.contains('dining') || text.contains('breakfast') || text.contains('lunch') || text.contains('gala')) {
    return Icons.restaurant_outlined;
  }
  if (text.contains('network')) return Icons.groups_outlined;
  return Icons.event_outlined;
}

Future<bool> rsvpToEvent(BuildContext context, String id) async {
  final res = await ApiService().rsvpEvent(id);
  if (context.mounted) {
    showToast(context, res['success'] ? 'You\'re going! We\'ve emailed your confirmation.' : (res['error'] ?? 'RSVP failed').toString(),
        error: !res['success']);
  }
  return res['success'] == true;
}

Future<bool> cancelEventRsvp(BuildContext context, String id, String title) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: const Text('Cancel RSVP?'),
      content: Text('You\'ll no longer be booked in for $title.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep my spot')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cancel RSVP', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  final res = await ApiService().cancelRsvp(id);
  if (context.mounted) {
    showToast(context, res['success'] ? 'Your RSVP has been cancelled.' : (res['error'] ?? 'Could not cancel').toString(),
        error: !res['success']);
  }
  return res['success'] == true;
}

void addEventToCalendar(dynamic e) {
  final start = Fmt.parse(e['event_date']) ?? DateTime.now();
  cal.Add2Calendar.addEvent2Cal(cal.Event(
    title: (e['title'] ?? 'Reliiance event').toString(),
    description: (e['description'] ?? '').toString(),
    location: (e['location'] ?? '').toString(),
    startDate: start,
    endDate: start.add(const Duration(hours: 2)), // events don't have an end time yet
  ));
}

void openInviteGuestSheet(BuildContext context, dynamic e) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => InviteGuestSheet(
      eventId: e['id'].toString(),
      eventTitle: (e['title'] ?? 'this event').toString(),
      pointsText: _hasPoints(e, 'points_for_referring') ? eventPointsText(e, 'points_for_referring') : null,
    ),
  );
}

// ----------------- Events ----------------- //
class EventsTab extends StatefulWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _isLoading = true;
  bool _showPast = false;
  List<dynamic> _events = [];
  Map<String, Map<String, dynamic>> _myRsvps = {}; // event_id → {attended, rsvp_at}
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_events.isEmpty) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([_api.getEvents(), _api.getMyRsvps()]);
      if (results[0]['success'] && results[0]['data'] is List) _events = results[0]['data'];
      if (results[1]['success'] && results[1]['data'] is List) {
        _myRsvps = {
          for (final r in results[1]['data'] as List) r['event_id'].toString(): Map<String, dynamic>.from(r as Map)
        };
      }
    } catch (e) {
      debugPrint('Events load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Upcoming: start time in the future (soonest first). Past: already started (most recent first).
  // The search box matches title, description, location and category.
  List<dynamic> get _visible {
    final now = DateTime.now();
    final q = _query.toLowerCase();
    final list = _events.where((e) {
      if (q.isNotEmpty) {
        final text = '${e['title'] ?? ''} ${e['description'] ?? ''} ${e['location'] ?? ''} ${e['category'] ?? ''}'.toLowerCase();
        if (!text.contains(q)) return false;
      }
      final start = Fmt.parse(e['event_date']);
      if (start == null) return !_showPast;
      return _showPast ? !start.isAfter(now) : start.isAfter(now);
    }).toList();
    list.sort((a, b) {
      final da = Fmt.parse(a['event_date']) ?? DateTime(2100);
      final db = Fmt.parse(b['event_date']) ?? DateTime(2100);
      return _showPast ? db.compareTo(da) : da.compareTo(db);
    });
    return list;
  }

  Future<void> _rsvp(String id) async {
    setState(() => _busy.add(id));
    final ok = await rsvpToEvent(context, id);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      if (ok) _myRsvps[id] = {'event_id': id, 'attended': false};
    });
  }

  Future<void> _cancel(String id, String title) async {
    setState(() => _busy.add(id));
    final ok = await cancelEventRsvp(context, id, title);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      if (ok) _myRsvps.remove(id);
    });
  }

  Future<void> _openDetail(dynamic e) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e, rsvp: _myRsvps[e['id'].toString()])));
    _load(); // the member may have RSVP'd or cancelled on the detail screen
  }

  @override
  Widget build(BuildContext context) {
    final events = _visible;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 16, AppDimens.pageMargin, 16),
              child: Row(
                children: [
                  Expanded(child: Text('Events', style: AppTextStyles.h2)),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())).then((_) => _load()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: UiColors.border)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryGold, size: 18),
                        const SizedBox(width: 8),
                        Text('Check in', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin),
              child: DarkTextField(
                hint: 'Search events',
                controller: _search,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin),
              child: _segmented(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? const FriendlyLoader(message: 'Finding upcoming events…', layout: SkeletonLayout.cards)
                  : RefreshIndicator(
                      color: AppColors.primaryGold,
                      backgroundColor: AppColors.surfaceCard,
                      onRefresh: _load,
                      child: events.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 100),
                              Center(
                                  child: Text(
                                      _query.isNotEmpty
                                          ? 'No events match "$_query".'
                                          : _showPast
                                              ? 'No past events yet'
                                              : 'No upcoming events right now.\nCheck back soon.',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelMedium)),
                            ])
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 4, AppDimens.pageMargin, 24),
                              itemCount: events.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 18),
                              itemBuilder: (_, i) => _eventCard(events[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmented() {
    Widget tab(String label, bool past) {
      final selected = _showPast == past;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _showPast = past),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryGold : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.backgroundBase : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                )),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [tab('Upcoming', false), tab('Past', true)]),
    );
  }

  Widget _eventCard(dynamic e) {
    final id = e['id'].toString();
    final title = (e['title'] ?? 'Event').toString();
    final start = Fmt.parse(e['event_date']);
    final location = (e['location'] ?? '').toString();
    final rsvp = _myRsvps[id];
    final going = rsvp != null;
    final attended = rsvp?['attended'] == true;
    final busy = _busy.contains(id);
    final when = [Fmt.dayDate(start), if (start != null) Fmt.time(start), if (location.isNotEmpty) location].join(' · ');

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(e),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedHeader(seed: id, icon: eventIcon(e), imageUrl: e['image_url']?.toString(), height: 130),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(title, style: AppTextStyles.h3.copyWith(fontSize: 19))),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(when, style: AppTextStyles.labelMedium),
                  EventPointsPills(event: e, past: _showPast),
                  const SizedBox(height: 16),
                  if (_showPast)
                    EventPastFooter(attended: attended, going: going)
                  else if (busy)
                    const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)))
                  else if (going) ...[
                    Row(children: [
                      const Expanded(child: EventGoingBadge()),
                      const SizedBox(width: 10),
                      Expanded(child: OutlineAction(text: 'Add to calendar', onPressed: () => addEventToCalendar(e))),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text('Confirmation sent to your email · ', style: AppTextStyles.labelSmall),
                      GestureDetector(
                        onTap: () => _cancel(id, title),
                        child: Text('Cancel RSVP',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, decoration: TextDecoration.underline)),
                      ),
                    ]),
                  ] else
                    Row(children: [
                      Expanded(child: FilledAction(text: 'RSVP', onPressed: () => _rsvp(id))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlineAction(text: 'Invite a friend', onPressed: () => openInviteGuestSheet(context, e))),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "+50–100 pts for attending" / "+20 pts per friend you bring".
class EventPointsPills extends StatelessWidget {
  final dynamic event;
  final bool past;
  const EventPointsPills({Key? key, required this.event, this.past = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attend = _hasPoints(event, 'points_for_attending');
    final friend = _hasPoints(event, 'points_for_referring') && !past;
    if (!attend && !friend) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        if (attend) InfoPill('+${eventPointsText(event, 'points_for_attending')} pts for attending', highlight: true),
        if (friend) InfoPill('+${eventPointsText(event, 'points_for_referring')} pts per friend you bring'),
      ]),
    );
  }
}

class EventGoingBadge extends StatelessWidget {
  const EventGoingBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: UiColors.greenBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: UiColors.green.withOpacity(0.7), width: 1.2),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_rounded, color: UiColors.green, size: 20),
          SizedBox(width: 8),
          Text('You\'re going', style: TextStyle(color: UiColors.green, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      );
}

class EventPastFooter extends StatelessWidget {
  final bool attended;
  final bool going;
  const EventPastFooter({Key? key, required this.attended, required this.going}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = attended ? 'You attended this event' : (going ? 'You were booked in' : 'This event has ended');
    return Row(children: [
      Icon(attended ? Icons.check_circle_outline_rounded : Icons.history_rounded,
          color: attended ? UiColors.green : AppColors.textSecondary, size: 18),
      const SizedBox(width: 8),
      Text(text, style: AppTextStyles.labelMedium.copyWith(color: attended ? UiColors.green : AppColors.textSecondary)),
    ]);
  }
}

// ----------------- Event detail ----------------- //
class EventDetailScreen extends StatefulWidget {
  final dynamic event;
  final Map<String, dynamic>? rsvp;
  const EventDetailScreen({Key? key, required this.event, this.rsvp}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Map<String, dynamic>? _rsvp = widget.rsvp;
  bool _busy = false;

  dynamic get e => widget.event;

  Future<void> _rsvpNow() async {
    setState(() => _busy = true);
    final ok = await rsvpToEvent(context, e['id'].toString());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _rsvp = {'event_id': e['id'].toString(), 'attended': false};
    });
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    final ok = await cancelEventRsvp(context, e['id'].toString(), (e['title'] ?? 'this event').toString());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _rsvp = null;
    });
  }

  /// "Your rewards for this event": points for attending and for each friend you bring.
  Widget _rewardsCard(bool past) {
    Widget row(IconData icon, String points, String what) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: UiColors.goldBg, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primaryGold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('+$points points', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
                Text(what, style: AppTextStyles.labelSmall),
              ]),
            ),
          ]),
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your rewards for this event', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        if (_hasPoints(e, 'points_for_attending'))
          row(Icons.event_available_outlined, eventPointsText(e, 'points_for_attending'), 'For attending — check in on the day with the Check in button'),
        if (_hasPoints(e, 'points_for_referring') && !past)
          row(Icons.group_add_outlined, eventPointsText(e, 'points_for_referring'), 'For each friend you bring who checks in'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final id = e['id'].toString();
    final title = (e['title'] ?? 'Event').toString();
    final start = Fmt.parse(e['event_date']);
    final location = (e['location'] ?? '').toString();
    final category = (e['category'] ?? '').toString();
    final description = (e['description'] ?? '').toString().trim();
    final attendeeInfo = (e['attendee_info'] ?? '').toString().trim(); // parking, webinar link …
    final past = start != null && !start.isAfter(DateTime.now());
    final going = _rsvp != null;
    final attended = _rsvp?['attended'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                TintedHeader(seed: id, icon: eventIcon(e), imageUrl: e['image_url']?.toString(), height: 200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 18, AppDimens.pageMargin, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (category.isNotEmpty) ...[StatusChip(category), const SizedBox(height: 10)],
                    Text(title, style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    if (start != null) _infoRow(Icons.calendar_today_outlined, '${Fmt.dayDate(start)} · ${Fmt.time(start)}'),
                    if (location.isNotEmpty) _infoRow(Icons.place_outlined, location),
                    if (_hasPoints(e, 'points_for_attending') || _hasPoints(e, 'points_for_referring')) ...[
                      const SizedBox(height: 12),
                      _rewardsCard(past),
                    ],
                    const SizedBox(height: 20),
                    Text('About this event', style: AppTextStyles.h3.copyWith(fontSize: 17)),
                    const SizedBox(height: 8),
                    Text(description.isNotEmpty ? description : 'More details coming soon.',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.55)),
                    if (attendeeInfo.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: UiColors.goldBg,
                          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 20),
                            const SizedBox(width: 8),
                            Text('Good to know', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 8),
                          SelectableText(attendeeInfo, style: AppTextStyles.bodyMedium.copyWith(height: 1.5, color: AppColors.textPrimary)),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 12, AppDimens.pageMargin, 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: UiColors.border))),
            child: past
                ? EventPastFooter(attended: attended, going: going)
                : _busy
                    ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)))
                    : going
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            Row(children: [
                              const Expanded(child: EventGoingBadge()),
                              const SizedBox(width: 10),
                              Expanded(child: OutlineAction(text: 'Add to calendar', onPressed: () => addEventToCalendar(e))),
                            ]),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              TextButton(
                                onPressed: () => openInviteGuestSheet(context, e),
                                child: Text('Invite a friend', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
                              ),
                              TextButton(
                                onPressed: _cancel,
                                child: Text('Cancel RSVP', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                              ),
                            ]),
                          ])
                        : Row(children: [
                            Expanded(child: FilledAction(text: 'RSVP', onPressed: _rsvpNow)),
                            const SizedBox(width: 10),
                            Expanded(child: OutlineAction(text: 'Invite a friend', onPressed: () => openInviteGuestSheet(context, e))),
                          ]),
          ),
        ]),
      ),
    );
  }
}

/// Bottom sheet to invite a friend to a specific event (earns the "per friend you bring" points).
/// The friend gets an email invitation with the event details from no-reply.
class InviteGuestSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String? pointsText; // "20" or "20–50"; null when there are no points for bringing a friend
  const InviteGuestSheet({Key? key, required this.eventId, required this.eventTitle, this.pointsText}) : super(key: key);

  @override
  State<InviteGuestSheet> createState() => _InviteGuestSheetState();
}

class _InviteGuestSheetState extends State<InviteGuestSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter your friend\'s name and a valid email address.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final res = await ApiService().inviteGuests(widget.eventId, [
      {'guest_name': name, 'guest_email': email, if (_mobile.text.trim().isNotEmpty) 'guest_mobile': _mobile.text.trim()},
    ]);
    if (!mounted) return;
    if (res['success']) {
      final emailed = res['data'] is Map && Fmt.toInt(res['data']['emailed']) > 0;
      Navigator.pop(context);
      showToast(context, emailed
          ? 'Invitation emailed to $name.'
          : 'We\'ve noted $name as your guest. Let them know the details, and ask them to check in at the event.');
    } else {
      setState(() {
        _sending = false;
        _error = (res['error'] ?? 'Could not send the invitation').toString();
      });
    }
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
          Text('Invite a friend', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            widget.pointsText != null
                ? 'We\'ll email your friend an invitation to ${widget.eventTitle}. You earn ${widget.pointsText} points when they check in.'
                : 'We\'ll email your friend an invitation to ${widget.eventTitle}.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 18),
          LabeledField(label: 'Friend\'s name', child: DarkTextField(hint: 'Full name', controller: _name)),
          const SizedBox(height: 12),
          LabeledField(label: 'Email', child: DarkTextField(hint: 'name@example.com', controller: _email, keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 12),
          LabeledField(label: 'Mobile (optional)', child: DarkTextField(hint: '04XX XXX XXX', controller: _mobile, keyboardType: TextInputType.phone)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _sending
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : FilledAction(text: 'Send invitation', onPressed: _send),
          ),
        ],
      ),
    );
  }
}
