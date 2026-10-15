import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/core_widgets.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/loading.dart';

const int kLowStockThreshold = 20;

IconData rewardIcon(dynamic r) {
  final t = '${r['category'] ?? ''} ${r['title'] ?? ''}'.toLowerCase();
  if (t.contains('whale') || t.contains('cruise') || t.contains('boat')) return Icons.sailing_outlined;
  if (t.contains('skydive') || t.contains('parachute')) return Icons.paragliding_outlined;
  if (t.contains('helicopter') || t.contains('flight') || t.contains('travel')) return Icons.flight_outlined;
  if (t.contains('property') || t.contains('home')) return Icons.home_outlined;
  if (t.contains('movie') || t.contains('cinema') || t.contains('hoyts')) return Icons.movie_outlined;
  if (t.contains('dinner') || t.contains('dining') || t.contains('restaurant')) return Icons.restaurant_outlined;
  if (t.contains('card') || t.contains('voucher') || t.contains('shopping')) return Icons.card_giftcard_outlined;
  return Icons.redeem_outlined;
}

enum RewardSort { pointsLow, pointsHigh, newest }

extension on RewardSort {
  String get label => switch (this) {
        RewardSort.pointsLow => 'Points, low to high',
        RewardSort.pointsHigh => 'Points, high to low',
        RewardSort.newest => 'Newest',
      };
}

// ----------------- Rewards list ----------------- //
class RewardsTab extends StatefulWidget {
  const RewardsTab({Key? key}) : super(key: key);

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _rewards = [];
  Set<String> _wishlist = {};
  int _balance = 0;
  String _category = 'All';
  RewardSort _sort = RewardSort.pointsLow;
  String _query = '';

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
    if (_rewards.isEmpty) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([_api.getRewards(), _api.getMe(), _api.getWishlist()]);
      if (results[0]['success'] && results[0]['data'] is List) _rewards = results[0]['data'];
      if (results[1]['success']) _balance = Fmt.toInt(results[1]['data']['total_points']);
      if (results[2]['success'] && results[2]['data'] is List) {
        _wishlist = (results[2]['data'] as List).map((e) => e.toString()).toSet();
      }
    } catch (e) {
      debugPrint('Rewards load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Categories come from the rewards themselves, so the filter always matches the data.
  List<String> get _categories {
    final cats = _rewards
        .map((r) => (r['category'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', if (_wishlist.isNotEmpty) 'Wish list', ...cats];
  }

  List<dynamic> get _visible {
    final q = _query.toLowerCase();
    final list = _rewards.where((r) {
      final cat = (r['category'] ?? '').toString();
      if (_category == 'Wish list' && !_wishlist.contains(r['id'].toString())) return false;
      if (_category != 'All' && _category != 'Wish list' && cat != _category) return false;
      if (q.isEmpty) return true;
      return '${r['title'] ?? ''} ${r['description'] ?? ''} $cat'.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) {
      switch (_sort) {
        case RewardSort.pointsLow:
          return Fmt.toInt(a['points_required']).compareTo(Fmt.toInt(b['points_required']));
        case RewardSort.pointsHigh:
          return Fmt.toInt(b['points_required']).compareTo(Fmt.toInt(a['points_required']));
        case RewardSort.newest:
          return (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString());
      }
    });
    return list;
  }

  Future<void> _toggleWishlist(String id) async {
    final saved = _wishlist.contains(id);
    setState(() => saved ? _wishlist.remove(id) : _wishlist.add(id));
    final res = saved ? await _api.removeFromWishlist(id) : await _api.addToWishlist(id);
    if (!mounted) return;
    if (!res['success']) {
      setState(() => saved ? _wishlist.add(id) : _wishlist.remove(id));
      showToast(context, (res['error'] ?? 'Something went wrong').toString(), error: true);
    } else {
      showToast(context, saved ? 'Removed from your wish list' : 'Saved to your wish list');
    }
  }

  Future<void> _openDetail(dynamic reward) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RewardDetailScreen(reward: Map<String, dynamic>.from(reward), balance: _balance, saved: _wishlist.contains(reward['id'].toString()))),
    );
    if (mounted) _load(); // balance, stock and wish list may have changed
  }

  void _pick<T>(String title, List<T> options, T current, String Function(T) label, ValueChanged<T> onPicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options
                    .map((o) => ListTile(
                          title: Text(label(o), style: AppTextStyles.labelLarge),
                          trailing: o == current ? const Icon(Icons.check_rounded, color: AppColors.primaryGold) : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            onPicked(o);
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewards = _visible;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 16, AppDimens.pageMargin, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Rewards', style: AppTextStyles.h2)),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Your balance', style: AppTextStyles.labelSmall),
                    Text(Fmt.pts(_balance), style: AppTextStyles.h3.copyWith(color: AppColors.primaryGold, fontSize: 20)),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin),
              child: DarkTextField(
                hint: 'Search rewards, e.g. movie, Woolworths',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 14, AppDimens.pageMargin, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _pick<String>('Show', _categories, _category, (c) => c, (c) => setState(() => _category = c)),
                    child: _pickerLabel('Showing: ', _category),
                  ),
                  GestureDetector(
                    onTap: () => _pick<RewardSort>('Sort by', RewardSort.values, _sort, (s) => s.label, (s) => setState(() => _sort = s)),
                    child: _pickerLabel('Sort: ', _sort.label),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const FriendlyLoader(message: 'Loading rewards…', layout: SkeletonLayout.cards)
                  : RefreshIndicator(
                      color: AppColors.primaryGold,
                      backgroundColor: AppColors.surfaceCard,
                      onRefresh: _load,
                      child: rewards.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Text(
                                  _rewards.isEmpty ? 'No rewards available' : 'No rewards match. Try another search or category.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelMedium,
                                ),
                              ),
                            ])
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 8, AppDimens.pageMargin, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 296,
                              ),
                              itemCount: rewards.length,
                              itemBuilder: (_, i) => _card(rewards[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerLabel(String prefix, String value) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(prefix, style: AppTextStyles.labelMedium),
        Text(value, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
      ]);

  Widget _card(dynamic r) {
    final id = r['id'].toString();
    final cost = Fmt.toInt(r['points_required']);
    final stock = r['stock'] == null ? null : Fmt.toInt(r['stock']);
    final soldOut = stock != null && stock <= 0;
    final lowStock = stock != null && stock > 0 && stock <= kLowStockThreshold;
    final affordable = _balance >= cost;
    final saved = _wishlist.contains(id);

    Widget statusLine;
    if (soldOut) {
      statusLine = Text('Sold out', style: AppTextStyles.labelSmall.copyWith(color: UiColors.red));
    } else if (affordable) {
      statusLine = Text(lowStock ? 'Only $stock left' : 'You can afford this',
          style: AppTextStyles.labelSmall.copyWith(color: lowStock ? AppColors.primaryGold : UiColors.green));
    } else {
      statusLine = Text('Need ${Fmt.number(cost - _balance)} more${lowStock ? ' · Only $stock left' : ''}',
          maxLines: 2, style: AppTextStyles.labelSmall);
    }

    final Widget action;
    if (affordable && !soldOut) {
      action = OutlineAction(text: 'View & redeem', color: AppColors.primaryGold, onPressed: () => _openDetail(r));
    } else {
      action = OutlineAction(
        text: saved ? 'Saved ✓' : 'Save to wish list',
        color: saved ? AppColors.primaryGold : AppColors.textPrimary,
        onPressed: () => _toggleWishlist(id),
      );
    }

    return GestureDetector(
      onTap: () => _openDetail(r),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedHeader(seed: id, icon: rewardIcon(r), imageUrl: r['image_url']?.toString(), height: 108),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((r['title'] ?? 'Reward').toString(),
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                    const SizedBox(height: 6),
                    Text(Fmt.pts(cost),
                        style: TextStyle(color: affordable ? AppColors.primaryGold : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    statusLine,
                    const Spacer(),
                    SizedBox(width: double.infinity, child: action),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Reward detail ----------------- //
class RewardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reward;
  final int balance;
  final bool saved;
  const RewardDetailScreen({Key? key, required this.reward, required this.balance, this.saved = false}) : super(key: key);

  @override
  State<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends State<RewardDetailScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _r;
  late int _balance;
  late bool _saved;
  bool _redeeming = false;
  bool _termsOpen = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _r = widget.reward;
    _balance = widget.balance;
    _saved = widget.saved;
    // Refresh in case the list was stale (stock, new fields)
    _api.getReward(_r['id'].toString()).then((res) {
      if (mounted && res['success'] && res['data'] is Map) setState(() => _r = Map<String, dynamic>.from(res['data']));
    });
  }

  int get _cost => Fmt.toInt(_r['points_required']);
  int? get _stock => _r['stock'] == null ? null : Fmt.toInt(_r['stock']);

  Future<void> _redeem() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Confirm redemption'),
        content: Text('Redeem ${_r['title']} for ${Fmt.pts(_cost)}?\nYour new balance will be ${Fmt.pts(_balance - _cost)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Redeem', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _redeeming = true);
    final res = await _api.redeemReward(_r['id'].toString());
    if (!mounted) return;
    setState(() => _redeeming = false);
    if (!res['success']) {
      showToast(context, (res['error'] ?? 'Redemption failed').toString(), error: true);
      return;
    }
    _changed = true;
    final reference = (res['data']?['id'] ?? '').toString();
    final shortRef = reference.length >= 8 ? reference.substring(0, 8).toUpperCase() : reference.toUpperCase();
    setState(() => _balance -= _cost);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: UiColors.greenBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: UiColors.green, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Request received', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('We\'ve emailed you a confirmation. Your request shows as Pending until it\'s approved and sent.',
              textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          if (shortRef.isNotEmpty) Text('Reference: $shortRef', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold)),
          const SizedBox(height: 4),
          Text('New balance: ${Fmt.pts(_balance)}', style: AppTextStyles.labelMedium),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledAction(text: 'Done', onPressed: () => Navigator.pop(ctx))),
        ]),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleSave() async {
    final id = _r['id'].toString();
    final wasSaved = _saved;
    setState(() => _saved = !wasSaved);
    final res = wasSaved ? await _api.removeFromWishlist(id) : await _api.addToWishlist(id);
    if (!mounted) return;
    if (!res['success']) {
      setState(() => _saved = wasSaved);
      showToast(context, (res['error'] ?? 'Something went wrong').toString(), error: true);
    } else {
      _changed = true;
    }
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primaryGold, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.labelSmall),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.labelLarge),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final title = (_r['title'] ?? 'Reward').toString();
    final category = (_r['category'] ?? '').toString();
    final description = (_r['description'] ?? '').toString();
    final whatYouGet = (_r['what_you_get'] ?? '').toString();
    final delivery = (_r['delivery_info'] ?? '').toString();
    final expiry = (_r['expiry_info'] ?? '').toString();
    final terms = (_r['terms'] ?? '').toString();
    final stock = _stock;
    final soldOut = stock != null && stock <= 0;
    final affordable = _balance >= _cost;
    final info = <Widget>[
      if (whatYouGet.isNotEmpty) _infoRow(Icons.card_giftcard_outlined, 'What you get', whatYouGet),
      if (delivery.isNotEmpty) _infoRow(Icons.mail_outline_rounded, 'How it\'s delivered', delivery),
      if (expiry.isNotEmpty) _infoRow(Icons.schedule_rounded, 'Expires', expiry),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(children: [
                    TintedHeader(seed: _r['id'].toString(), icon: rewardIcon(_r), imageUrl: _r['image_url']?.toString(), height: 240),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: _circleButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context, _changed)),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: _circleButton(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, _toggleSave,
                          color: _saved ? AppColors.primaryGold : Colors.white),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 18, AppDimens.pageMargin, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                            child: Text(category, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(height: 10),
                        Text(title, style: AppTextStyles.h2),
                        const SizedBox(height: 6),
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Text(Fmt.pts(_cost), style: AppTextStyles.h3.copyWith(color: AppColors.primaryGold)),
                          const SizedBox(width: 10),
                          if (soldOut)
                            Text('Sold out', style: AppTextStyles.labelMedium.copyWith(color: UiColors.red))
                          else if (stock != null && stock <= kLowStockThreshold)
                            Text('Only $stock left', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
                        ]),
                        if (_r['dollar_value'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Value: \$${Fmt.number(_r['dollar_value'] as num)}', style: AppTextStyles.labelMedium),
                        ],
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(description, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary, height: 1.5)),
                        ],
                        if (info.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
                            child: Column(children: [
                              for (int i = 0; i < info.length; i++) ...[
                                info[i],
                                if (i < info.length - 1) const Divider(height: 1, color: UiColors.border),
                              ],
                            ]),
                          ),
                        ],
                        if (terms.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => setState(() => _termsOpen = !_termsOpen),
                            child: Row(children: [
                              Text('Terms and conditions', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold)),
                              Icon(_termsOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.primaryGold),
                            ]),
                          ),
                          if (_termsOpen) ...[
                            const SizedBox(height: 8),
                            Text(terms, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppDimens.pageMargin, 14, AppDimens.pageMargin, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your balance', style: AppTextStyles.labelSmall),
                      Text(Fmt.pts(_balance), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(affordable ? 'After redeeming' : 'You need', style: AppTextStyles.labelSmall),
                      Text(affordable ? Fmt.pts(_balance - _cost) : '${Fmt.number(_cost - _balance)} more pts',
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primaryGold)),
                    ]),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _redeeming
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                      : (affordable && !soldOut)
                          ? FilledAction(text: 'Redeem for ${Fmt.pts(_cost)}', onPressed: _redeem)
                          : OutlineAction(
                              text: _saved ? 'Saved to wish list ✓' : 'Save to wish list',
                              color: _saved ? AppColors.primaryGold : AppColors.textPrimary,
                              onPressed: _toggleSave,
                            ),
                ),
                const SizedBox(height: 8),
                Text(
                  (affordable && !soldOut) ? 'We\'ll email you a confirmation with a reference number.' : (soldOut ? 'This reward is sold out.' : 'Keep earning points to unlock this reward.'),
                  style: AppTextStyles.labelSmall,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color color = Colors.white}) => Material(
        color: Colors.black.withOpacity(0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: color, size: 20)),
        ),
      );
}
