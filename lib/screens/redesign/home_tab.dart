import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../services/push_alerts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/loading.dart';
import '../../widgets/ui_kit.dart';
import 'help_screen.dart';
import 'loan_checkin_screen.dart';
import 'profile_screen.dart';
import 'welcome_tour.dart';

const _kNotificationsSeenKey = 'notifications_seen_at';

// ----------------- Home ----------------- //
class DashboardTab extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const DashboardTab({Key? key, required this.onNavigateToTab}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Welcome tour and phone-alert setup run once per app session, after Home first loads.
  static bool _onboardingChecked = false;
  static const _recentCount = 5; // the rest of the points history is under the bell

  final ApiService _api = ApiService();
  bool _isLoading = true;
  ProgramContact _contact = const ProgramContact();
  Map<String, dynamic>? _profile;
  List<dynamic> _activity = [];
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_profile == null) setState(() => _isLoading = true);
    try {
      var me = await _api.getMe();
      if (!me['success']) {
        // Retry once — the server can take a while to wake up
        await Future.delayed(const Duration(seconds: 5));
        me = await _api.getMe();
      }
      if (me['success']) _profile = me['data'];

      final results = await Future.wait([_api.getTransactions(), _api.getNotifications(), ProgramContact.load(refresh: true)]);
      _contact = results[2] as ProgramContact;
      final tx = results[0] as Map<String, dynamic>;
      if (tx['success'] && tx['data'] is List) _activity = tx['data'];
      final notes = results[1] as Map<String, dynamic>;
      if (notes['success'] && notes['data'] is List && (notes['data'] as List).isNotEmpty) {
        final latest = Fmt.parse((notes['data'] as List).first['at']);
        final seenRaw = await _api.storage.read(key: _kNotificationsSeenKey);
        final seen = Fmt.parse(seenRaw);
        _hasUnread = latest != null && (seen == null || latest.isAfter(seen));
      }
    } catch (e) {
      debugPrint('Home load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (_profile != null && !_onboardingChecked && mounted) {
      _onboardingChecked = true;
      await WelcomeTourScreen.showIfNew(context, _profile);
      await PushAlerts.register();
      final launchAlert = PushAlerts.takeLaunchAlert();
      if (launchAlert != null && mounted) openAlert(context, launchAlert);
    }
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _load());
  }

  void _openNotifications({bool history = false}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(showHistory: history, history: _activity)));
    if (mounted) setState(() => _hasUnread = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SafeArea(child: FriendlyLoader(message: 'Getting your points…', layout: SkeletonLayout.home)));
    }
    if (_profile == null) {
      return Scaffold(body: SafeArea(child: LoadErrorView(message: "We couldn't load your account.", onRetry: _load)));
    }

    final fullName = (_profile?['full_name'] ?? 'Member').toString();
    final firstName = fullName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M';
    final points = Fmt.toInt(_profile?['total_points']);
    final profileComplete = _profile?['profile_complete'] == true;
    final tier = _profile?['tier'] is Map ? Map<String, dynamic>.from(_profile!['tier']) : <String, dynamic>{};

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGold,
          backgroundColor: AppColors.surfaceCard,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 12, AppDimens.pageMargin, 24),
            children: [
              _header(initial, firstName),
              const SizedBox(height: 20),
              if (!profileComplete) ...[_profileBanner(), const SizedBox(height: 16)],
              _pointsCard(points, tier),
              const SizedBox(height: 16),
              Row(children: [
                _quickAction(Icons.person_add_alt_1_outlined, 'Refer a friend', () => widget.onNavigateToTab(1)),
                const SizedBox(width: 12),
                _quickAction(Icons.card_giftcard_outlined, 'Redeem', () => widget.onNavigateToTab(2)),
                const SizedBox(width: 12),
                _quickAction(Icons.calendar_today_outlined, 'Events', () => widget.onNavigateToTab(3)),
              ]),
              const SizedBox(height: 16),
              BrokerCard(info: _contact),
              const SizedBox(height: 28),
              Text('Recent activity', style: AppTextStyles.h3),
              const SizedBox(height: 14),
              if (_activity.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No activity yet. Refer a friend or attend an event to earn points.',
                      textAlign: TextAlign.center, style: AppTextStyles.labelMedium)),
                )
              else ...[
                ..._activity.take(_recentCount).map((a) => ActivityRow(item: a)),
                if (_activity.length > _recentCount)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () => _openNotifications(history: true),
                        icon: const Icon(Icons.notifications_none_rounded, size: 18),
                        label: const Text('Older activity is under the bell at the top'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String initial, String firstName) {
    return Row(
      children: [
        GestureDetector(
          onTap: _openProfile,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: UiColors.goldBg,
            child: Text(initial, style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _openProfile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Fmt.greeting()},', style: AppTextStyles.labelMedium),
                Text(firstName, style: AppTextStyles.h3),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: _openNotifications,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle, border: Border.all(color: UiColors.border)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                if (_hasUnread)
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surfaceCard, width: 1.5)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileBanner() {
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Complete your profile to unlock all features',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold))),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryGold, size: 20),
        ]),
      ),
    );
  }

  Widget _pointsCard(int points, Map<String, dynamic> tier) {
    final tierName = tier['name']?.toString();
    final nextName = tier['next_name']?.toString();
    final toNext = tier['points_to_next'];
    final double progress = (tier['progress'] is num) ? (tier['progress'] as num).clamp(0, 1).toDouble() : 0.0;
    final progressText = nextName != null && toNext != null
        ? '${Fmt.number(toNext)} points to $nextName'
        : (tierName != null ? 'You\'re at the top tier' : '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: UiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total points', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 4),
                    Text(Fmt.number(points), style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 42, height: 1.1)),
                  ],
                ),
              ),
              if (tierName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: UiColors.goldBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_border_rounded, color: AppColors.primaryGold, size: 18),
                    const SizedBox(width: 6),
                    Text('$tierName member', style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.inputFill,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
            ),
          ),
          const SizedBox(height: 12),
          Text(progressText, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: UiColors.border),
          ),
          child: Column(children: [
            Icon(icon, color: AppColors.primaryGold, size: 26),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

/// One Recent activity row: title, date + status chip, signed points.
class ActivityRow extends StatelessWidget {
  final dynamic item;
  const ActivityRow({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pts = Fmt.toInt(item['points']);
    final title = (item['title'] ?? item['description'] ?? 'Points update').toString();
    final status = (item['status_label'] ?? '').toString();
    final reason = (item['reason'] ?? '').toString();
    final dateText = [Fmt.date(Fmt.parse(item['created_at'])), if (reason.isNotEmpty) reason].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(dateText, style: AppTextStyles.labelSmall),
                    if (status.isNotEmpty) StatusChip(status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(Fmt.signedPts(pts),
              style: AppTextStyles.h3.copyWith(fontSize: 18, color: pts >= 0 ? UiColors.green : UiColors.red)),
        ],
      ),
    );
  }
}

// ----------------- All activity (points statement) ----------------- //
class PointsHistoryList extends StatefulWidget {
  final List<dynamic>? initial;
  const PointsHistoryList({Key? key, this.initial}) : super(key: key);

  @override
  State<PointsHistoryList> createState() => _PointsHistoryListState();
}

class _PointsHistoryListState extends State<PointsHistoryList> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _items = widget.initial ?? [];
    _loading = _items.isEmpty;
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService().getTransactions();
    if (!mounted) return;
    setState(() {
      if (res['success'] && res['data'] is List) _items = res['data'];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const FriendlyLoader(message: 'Loading your points history…')
        : RefreshIndicator(
            color: AppColors.primaryGold,
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text('No activity yet', style: AppTextStyles.labelMedium)),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(AppDimens.pageMargin),
                    children: _items.map((a) => ActivityRow(item: a)).toList(),
                  ),
          );
  }
}

// ----------------- Notifications (bell): Updates + full points history ----------------- //
class NotificationsScreen extends StatelessWidget {
  final bool showHistory;
  final List<dynamic>? history;
  const NotificationsScreen({Key? key, this.showHistory = false, this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: showHistory ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryGold,
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'Updates'), Tab(text: 'Points history')],
          ),
        ),
        body: TabBarView(children: [const UpdatesList(), PointsHistoryList(initial: history)]),
      ),
    );
  }
}

class UpdatesList extends StatefulWidget {
  const UpdatesList({Key? key}) : super(key: key);

  @override
  State<UpdatesList> createState() => _UpdatesListState();
}

class _UpdatesListState extends State<UpdatesList> {
  final ApiService _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.getNotifications();
    if (!mounted) return;
    setState(() {
      if (res['success'] && res['data'] is List) _items = res['data'];
      _loading = false;
    });
    try {
      await _api.storage.write(key: _kNotificationsSeenKey, value: DateTime.now().toUtc().toIso8601String());
    } catch (_) {}
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'reward':
        return Icons.card_giftcard_outlined;
      case 'referral':
        return Icons.people_outline_rounded;
      case 'event':
        return Icons.calendar_today_outlined;
      case 'loan':
        return Icons.home_work_outlined;
      default:
        return Icons.star_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
          ? const FriendlyLoader(message: 'Checking for updates…')
          : RefreshIndicator(
              color: AppColors.primaryGold,
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Center(child: Text('No updates yet', style: AppTextStyles.labelMedium)),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppDimens.pageMargin),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = _items[i];
                        final body = (n['body'] ?? '').toString();
                        final links = _linksIn(body);
                        final text = body.split('\n').where((l) => !links.any((k) => l.endsWith(k.$2))).join('\n').trim();
                        final isCheckin = n['type'] == 'loan_checkin';
                        return GestureDetector(
                          onTap: isCheckin
                              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanCheckinScreen(message: body)))
                              : null,
                          child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: UiColors.goldBg, shape: BoxShape.circle),
                                child: Icon(_icon((n['kind'] ?? '').toString()), color: AppColors.primaryGold, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((n['title'] ?? '').toString(), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                                    if (text.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(text, style: AppTextStyles.bodyMedium),
                                    ],
                                    for (final link in links)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.primaryGold),
                                        onPressed: () => launchUrl(Uri.parse(link.$2), mode: LaunchMode.externalApplication),
                                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                        label: Text(link.$1),
                                      ),
                                    if (isCheckin)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('Request a review →', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(Fmt.relative(Fmt.parse(n['at'])), style: AppTextStyles.labelSmall.copyWith(color: UiColors.muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
            );
  }

  /// "Slides: https://…" lines in event thank-yous become link buttons.
  static List<(String, String)> _linksIn(String body) => RegExp(r'^(Slides|Recording|More information): (https?://\S+)$', multiLine: true)
      .allMatches(body)
      .map((m) => (m.group(1) == 'Recording' ? 'Watch the recording' : m.group(1) == 'Slides' ? 'View the slides' : 'More information', m.group(2)!))
      .toList();
}

// ----------------- What do tiers give me? ----------------- //
class TiersScreen extends StatefulWidget {
  final String? currentTier;
  const TiersScreen({Key? key, this.currentTier}) : super(key: key);

  @override
  State<TiersScreen> createState() => _TiersScreenState();
}

class _TiersScreenState extends State<TiersScreen> {
  List<dynamic> _tiers = [];
  String _basis = 'lifetime';
  String _intro = '';
  String? _currentTier;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentTier = widget.currentTier;
    _load();
  }

  Future<void> _load() async {
    final api = ApiService();
    final results = await Future.wait([api.getTiers(), if (_currentTier == null) api.getMe()]);
    if (!mounted) return;
    setState(() {
      final res = results[0];
      if (res['success'] && res['data'] is Map) {
        _tiers = (res['data']['tiers'] as List?) ?? [];
        _basis = (res['data']['basis'] ?? 'lifetime').toString();
        _intro = (res['data']['intro'] ?? '').toString().trim();
      }
      if (results.length > 1 && results[1]['success'] == true && results[1]['data'] is Map) {
        final tier = results[1]['data']['tier'];
        if (tier is Map) _currentTier = tier['name']?.toString();
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Staff can write their own intro on the admin website (Help & Contact → Member tiers).
    final basisText = _intro.isNotEmpty
        ? _intro
        : _basis == 'balance'
            ? 'Your tier is based on your current points balance.'
            : 'Your tier is based on all the points you\'ve earned, so redeeming rewards never moves you down.';
    return Scaffold(
      appBar: AppBar(title: const Text('Member tiers')),
      body: _loading
          ? const FriendlyLoader(message: 'Loading member tiers…', layout: SkeletonLayout.cards)
          : ListView(
              padding: const EdgeInsets.all(AppDimens.pageMargin),
              children: [
                Text(basisText, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 20),
                ..._tiers.map((t) {
                  final isCurrent = t['name'] == _currentTier;
                  final benefits = (t['benefits'] as List?) ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: isCurrent ? AppColors.primaryGold : UiColors.border, width: isCurrent ? 1.5 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.star_border_rounded, color: AppColors.primaryGold),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t['name'].toString(), style: AppTextStyles.h3.copyWith(fontSize: 18))),
                          if (isCurrent) const StatusChip('Your tier'),
                        ]),
                        const SizedBox(height: 6),
                        Text(Fmt.toInt(t['min_points']) == 0 ? 'Where every member starts' : 'From ${Fmt.pts(t['min_points'])}',
                            style: AppTextStyles.labelSmall),
                        if (benefits.isNotEmpty) const SizedBox(height: 12),
                        ...benefits.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_rounded, size: 16, color: UiColors.green),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(b.toString(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                              ]),
                            )),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

/// Opens the screen for a tapped phone alert.
void openAlert(BuildContext context, Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString();
  final route = type == 'loan_checkin'
      ? MaterialPageRoute(builder: (_) => const LoanCheckinScreen())
      : MaterialPageRoute(builder: (_) => const NotificationsScreen());
  Navigator.of(context, rootNavigator: true).push(route);
}
