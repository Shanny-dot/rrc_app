import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/core_widgets.dart';
import '../../widgets/ui_kit.dart';
import '../dashboard_screens.dart' show QRScannerScreen;
import '../../widgets/loading.dart';

// ----------------- Events ----------------- //
class EventsTab extends StatefulWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final ApiService _api = ApiService();
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
  List<dynamic> get _visible {
    final now = DateTime.now();
    final list = _events.where((e) {
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
    final res = await _api.rsvpEvent(id);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      if (res['success']) _myRsvps[id] = {'event_id': id, 'attended': false};
    });
    showToast(context, res['success'] ? 'You\'re going! We\'ve emailed your confirmation.' : (res['error'] ?? 'RSVP failed').toString(),
        error: !res['success']);
  }

  Future<void> _cancel(String id, String title) async {
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
    if (confirmed != true) return;
    setState(() => _busy.add(id));
    final res = await _api.cancelRsvp(id);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      if (res['success']) _myRsvps.remove(id);
    });
    showToast(context, res['success'] ? 'Your RSVP has been cancelled.' : (res['error'] ?? 'Could not cancel').toString(),
        error: !res['success']);
  }

  void _addToCalendar(dynamic e) {
    final start = Fmt.parse(e['event_date']) ?? DateTime.now();
    cal.Add2Calendar.addEvent2Cal(cal.Event(
      title: (e['title'] ?? 'Reliance event').toString(),
      description: (e['description'] ?? '').toString(),
      location: (e['location'] ?? '').toString(),
      startDate: start,
      endDate: start.add(const Duration(hours: 2)), // events don't have an end time yet
    ));
  }

  void _invite(dynamic e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => InviteGuestSheet(
        eventId: e['id'].toString(),
        eventTitle: (e['title'] ?? 'this event').toString(),
        pointsPerFriend: Fmt.toInt(e['points_for_referring']),
      ),
    );
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
                              Center(child: Text(_showPast ? 'No past events yet' : 'No upcoming events right now.\nCheck back soon.',
                                  textAlign: TextAlign.center, style: AppTextStyles.labelMedium)),
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

  IconData _iconFor(dynamic e) {
    final text = '${e['category'] ?? ''} ${e['title'] ?? ''} ${e['location'] ?? ''}'.toLowerCase();
    if (text.contains('online') || text.contains('webinar') || text.contains('virtual')) return Icons.desktop_windows_outlined;
    if (text.contains('home') || text.contains('buyer') || text.contains('property') || text.contains('real estate')) return Icons.home_outlined;
    if (text.contains('dinner') || text.contains('dining') || text.contains('breakfast') || text.contains('lunch') || text.contains('gala')) {
      return Icons.restaurant_outlined;
    }
    if (text.contains('network')) return Icons.groups_outlined;
    return Icons.event_outlined;
  }

  Widget _eventCard(dynamic e) {
    final id = e['id'].toString();
    final title = (e['title'] ?? 'Event').toString();
    final start = Fmt.parse(e['event_date']);
    final location = (e['location'] ?? '').toString();
    final attendPts = Fmt.toInt(e['points_for_attending']);
    final friendPts = Fmt.toInt(e['points_for_referring']);
    final rsvp = _myRsvps[id];
    final going = rsvp != null;
    final attended = rsvp?['attended'] == true;
    final busy = _busy.contains(id);
    final when = [Fmt.dayDate(start), if (start != null) Fmt.time(start), if (location.isNotEmpty) location].join(' · ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedHeader(seed: id, icon: _iconFor(e), imageUrl: e['image_url']?.toString(), height: 130),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3.copyWith(fontSize: 19)),
                const SizedBox(height: 4),
                Text(when, style: AppTextStyles.labelMedium),
                if (attendPts > 0 || friendPts > 0) const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (attendPts > 0) InfoPill('+${Fmt.number(attendPts)} pts for attending', highlight: true),
                  if (friendPts > 0 && !_showPast) InfoPill('+${Fmt.number(friendPts)} pts per friend you bring'),
                ]),
                const SizedBox(height: 16),
                if (_showPast)
                  _pastFooter(attended, going)
                else if (busy)
                  const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)))
                else if (going) ...[
                  Row(children: [
                    Expanded(child: _goingBadge()),
                    const SizedBox(width: 10),
                    Expanded(child: OutlineAction(text: 'Add to calendar', onPressed: () => _addToCalendar(e))),
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
                    Expanded(child: OutlineAction(text: 'Invite a friend', onPressed: () => _invite(e))),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goingBadge() => Container(
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

  Widget _pastFooter(bool attended, bool going) {
    final text = attended ? 'You attended this event' : (going ? 'You were booked in' : 'This event has ended');
    return Row(children: [
      Icon(attended ? Icons.check_circle_outline_rounded : Icons.history_rounded,
          color: attended ? UiColors.green : AppColors.textSecondary, size: 18),
      const SizedBox(width: 8),
      Text(text, style: AppTextStyles.labelMedium.copyWith(color: attended ? UiColors.green : AppColors.textSecondary)),
    ]);
  }
}

/// Bottom sheet to invite a friend to a specific event (earns the "per friend you bring" points).
class InviteGuestSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final int pointsPerFriend;
  const InviteGuestSheet({Key? key, required this.eventId, required this.eventTitle, required this.pointsPerFriend}) : super(key: key);

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
      Navigator.pop(context);
      showToast(context, 'Invitation sent to $name.');
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
            widget.pointsPerFriend > 0
                ? 'Bring a friend to ${widget.eventTitle} and earn ${Fmt.pts(widget.pointsPerFriend)} when they check in.'
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
