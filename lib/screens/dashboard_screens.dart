import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'auth_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/core_widgets.dart';
import 'import_contacts_screen.dart';

// ----------------- Main Navigation Layout ----------------- //

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({Key? key}) : super(key: key);

  @override
  _MainAppScaffoldState createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      DashboardTab(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const ReferralsTab(),
      const RewardsTab(),
      const EventsTab(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceCard, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.backgroundBase,
          selectedItemColor: AppColors.primaryGold,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.labelSmall,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Referrals'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_rounded), label: 'Rewards'),
            BottomNavigationBarItem(icon: Icon(Icons.event_rounded), label: 'Events'),
          ],
        ),
      ),
    );
  }
}

// ----------------- Dashboard ----------------- //
class DashboardTab extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DashboardTab({Key? key, required this.onNavigateToTab}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  Map<String, dynamic>? _userProfile;
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      var profileResult = await _apiService.getMe();
      if (profileResult['success']) {
        _userProfile = profileResult['data'];
      } else {
        // Retry once after delay — handles Render free-tier cold-start (~50s spin-up)
        await Future.delayed(const Duration(seconds: 5));
        profileResult = await _apiService.getMe();
        if (profileResult['success']) _userProfile = profileResult['data'];
      }

      final activityResult = await _apiService.getTransactions();
      if (activityResult['success'] && activityResult['data'] is List) {
        _recentActivity = (activityResult['data'] as List).take(3).toList();
      }
    } catch (e) {
      debugPrint("Dashboard Error: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    final String fullName = _userProfile?['full_name'] ?? 'User';
    final String firstName = fullName.split(' ').first;
    final String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
    final int points = _userProfile?['total_points'] ?? 0;
    final bool profileComplete = _userProfile?['profile_complete'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _fetchDashboardData());
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceCard,
                child: Text(initials, style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning,', style: AppTextStyles.labelSmall),
                Text(firstName, style: AppTextStyles.labelLarge),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: _fetchDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          children: [
            // Profile Banner
            if (!profileComplete)
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _fetchDashboardData());
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.sectionGap),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Complete your profile to unlock all features', 
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryGold, size: 20),
                    ],
                  ),
                ),
              ),

            // Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.inputFill),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Points', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  Text('$points', style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 40)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gold Tier', style: AppTextStyles.labelLarge),
                      Text('1000 to Platinum', style: AppTextStyles.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (points % 1000) / 1000, // simple calc for demo
                    backgroundColor: AppColors.backgroundBase,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sectionGap),

            // Quick Actions
            Row(
              children: [
                _buildQuickAction(Icons.person_add_rounded, 'Refer Friend', () => widget.onNavigateToTab(1)),
                const SizedBox(width: 12),
                _buildQuickAction(Icons.card_giftcard_rounded, 'Redeem', () => widget.onNavigateToTab(2)),
                const SizedBox(width: 12),
                _buildQuickAction(Icons.event_rounded, 'Events', () => widget.onNavigateToTab(3)),
              ],
            ),
            const SizedBox(height: 32),

            Text('Recent Activity', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            
            if (_recentActivity.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No recent activity', style: AppTextStyles.labelMedium)),
              )
            else
              ..._recentActivity.map((activity) {
                final isPositive = activity['points'] > 0;
                final sign = isPositive ? '+' : '';
                return _buildActivityRow(
                  _getIconForType(activity['type']),
                  activity['description'] ?? activity['type'],
                  activity['created_at'] != null ? activity['created_at'].toString().split('T')[0] : 'Just now',
                  sign + activity['points'].toString(),
                  isPositive,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('signup')) return Icons.star_rounded;
    if (type.contains('referral')) return Icons.person_add_rounded;
    if (type.contains('event')) return Icons.event_rounded;
    if (type.contains('redeem')) return Icons.card_giftcard_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBase,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.inputFill),
                ),
                child: Icon(icon, color: AppColors.primaryGold, size: 24),
              ),
              const SizedBox(height: 12),
              Text(label, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityRow(IconData icon, String title, String time, String points, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: AppTextStyles.labelLarge),
                 const SizedBox(height: 4),
                 Text(time, style: AppTextStyles.labelSmall),
               ],
            ),
          ),
          Text(
            points, 
            style: AppTextStyles.h3.copyWith(
              color: isPositive ? AppColors.primaryGold : AppColors.error,
              fontSize: 18,
            )
          ),
        ],
      ),
    );
  }
}

// ----------------- Referrals ----------------- //
class ReferralsTab extends StatefulWidget {
  const ReferralsTab({Key? key}) : super(key: key);

  @override
  State<ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<ReferralsTab> {
  int _totalEarned = 0;
  List<dynamic> _referrals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiService();
      // Fetch both profile points and referrals concurrently 
      final results = await Future.wait([
        api.getMe(),
        api.getReferrals()
      ]);

      final meRes = results[0];
      final refRes = results[1];

      if (mounted) {
        setState(() {
          if (meRes['success']) {
            _totalEarned = meRes['data']['total_points'] ?? 0;
          }
          if (refRes['success']) {
             _referrals = refRes['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
        : ListView(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        children: [
          Center(
            child: Column(
              children: [
                Text('Total Points', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_totalEarned', style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 40)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, color: AppColors.primaryGold, size: 32),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  Icons.person_add_rounded, 
                  'Refer a Friend', 
                  'Enter details manually',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferFormScreen())),
                ),
              ),
              const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      Icons.contacts_rounded, 
                      'Import Contacts', 
                      'Sync address book',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportContactsScreen())),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 32),
          
          Text('Referral History', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          
          if (_referrals.isEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 20),
               child: Center(child: Text("No referrals yet. Start inviting!", style: AppTextStyles.bodyMedium)),
             )
          else
             ..._referrals.map((ref) {
               // Map backend status to UI color & points logic
               String status = ref['status'] ?? 'pending';
               Color statusColor = AppColors.primaryGold;
               String pointsAwarded = '0'; // default pending/failed

               if (status.toLowerCase() == 'registered') {
                  statusColor = AppColors.success;
                  pointsAwarded = '+100'; // Or whatever your backend standard is
               } else if (status.toLowerCase() == 'approved') {
                  statusColor = AppColors.success;
                  pointsAwarded = '+500';
               }

               return _buildHistoryRow(
                 ref['referred_name'] ?? 'Friend', 
                 status.toUpperCase(), 
                 pointsAwarded, 
                 statusColor
               );
             }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.inputFill),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 40),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.labelLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String name, String status, String points, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.inputFill,
            child: Text(name[0], style: const TextStyle(color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Text(points, style: AppTextStyles.h3.copyWith(color: AppColors.primaryGold)),
        ],
      ),
    );
  }
}

class ReferFormScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;

  const ReferFormScreen({
    Key? key,
    this.initialName,
    this.initialPhone,
    this.initialEmail,
  }) : super(key: key);

  @override
  State<ReferFormScreen> createState() => _ReferFormScreenState();
}

class _ReferFormScreenState extends State<ReferFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _phoneController.text = widget.initialPhone ?? '';
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService().submitReferral({
      'referred_name': name,
      'referred_mobile': phone,
      'referred_email': email,
    });
    setState(() => _isLoading = false);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral successful!')));
      Navigator.pop(context, true); // Return true to indicate success and refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Submission failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer a Friend')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        child: Column(
          children: [
            DarkTextField(hint: 'Full Name', controller: _nameController),
            const SizedBox(height: 16),
            DarkTextField(hint: 'Mobile Number', keyboardType: TextInputType.phone, controller: _phoneController),
            const SizedBox(height: 16),
            DarkTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress, controller: _emailController),
            const Spacer(),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : GoldButton(text: 'Send Referral', onPressed: _submit),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ----------------- Rewards ----------------- //
class RewardsTab extends StatefulWidget {
  const RewardsTab({Key? key}) : super(key: key);

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _rewards = [];

  @override
  void initState() {
    super.initState();
    _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getRewards();
      if (result['success'] && result['data'] is List) {
        _rewards = result['data'];
      }
    } catch (e) {
      debugPrint("Rewards Error: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('Experiences', false),
                _buildFilterChip('Dining', false),
                _buildFilterChip('Travel', false),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : _rewards.isEmpty 
                ? Center(child: Text("No rewards available", style: AppTextStyles.labelMedium))
                : RefreshIndicator(
                    color: AppColors.primaryGold,
                    backgroundColor: AppColors.surfaceCard,
                    onRefresh: _fetchRewards,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(AppDimens.pageMargin),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _rewards.length,
                      itemBuilder: (context, index) {
                        final reward = _rewards[index];
                        return _buildRewardCard(
                          context,
                          id: reward['id'].toString(),
                          title: reward['title'] ?? 'Reward',
                          points: (reward['points_required'] ?? 0).toString() + ' pts',
                          imageUrl: reward['image_url'],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGold : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: isSelected ? AppColors.primaryGold : AppColors.inputFill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.backgroundBase : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, {required String id, required String title, required String points, String? imageUrl}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
                      child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary))),
                    )
                  : const Center(child: Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 40)),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(title, style: AppTextStyles.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                   PointsBadge(points: points),
                   SizedBox(
                     width: double.infinity,
                     height: 36,
                     child: ElevatedButton(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.transparent,
                         foregroundColor: AppColors.primaryGold,
                         elevation: 0,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                           side: const BorderSide(color: AppColors.primaryGold),
                         ),
                       ),
                       onPressed: () {
                          _showRedeemBottomSheet(context, id, title, points);
                       },
                       child: const Text('Redeem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                     ),
                   ),
                 ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showRedeemBottomSheet(BuildContext context, String id, String title, String pts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Confirm Redemption', style: AppTextStyles.h2),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reward:', style: AppTextStyles.labelMedium),
                  Expanded(child: Text(title, style: AppTextStyles.labelLarge, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cost:', style: AppTextStyles.labelMedium),
                  Text(pts, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold)),
                ],
              ),
              const SizedBox(height: 24),
              GoldButton(text: 'Confirm Redeem', onPressed: () async {
                // Show floating loading indicator
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)));
                
                final res = await _apiService.redeemReward(id);
                
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close bottom sheet
                
                if (res['success']) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redemption successful! Processing your reward.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
                   _fetchRewards(); // refresh list
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Redemption failed', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
                }
              }),
              const SizedBox(height: 12),
              GoldButton(text: 'Cancel', isTextLink: true, onPressed: () => Navigator.pop(context)),
            ],
          ),
        );
      },
    );
  }
}

// ----------------- Events ----------------- //
class EventsTab extends StatefulWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getEvents();
      if (result['success'] && result['data'] is List) {
        _events = result['data'];
      }
    } catch (e) {
      debugPrint("Events Error: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRsvp(String eventId) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)));
    final res = await _apiService.rsvpEvent(eventId);
    Navigator.pop(context); // pop dialog
    if (res['success']) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully RSVP\'d! See you there!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
    } else {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'RSVP Failed', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
    }
  }

  void _handleRefer(String eventId) {
     // Ideally pass eventId to ReferFormScreen to link the guest automatically
     Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.backgroundBase,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan QR', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
        },
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.pageMargin),
            child: DarkTextField(
              hint: 'Search exclusive events...',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : _events.isEmpty
                ? Center(child: Text("No events available", style: AppTextStyles.labelMedium))
                : RefreshIndicator(
                    color: AppColors.primaryGold,
                    backgroundColor: AppColors.surfaceCard,
                    onRefresh: _fetchEvents,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin, vertical: 8),
                      itemCount: _events.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        final dateStr = event['event_date'] != null 
                             ? event['event_date'].toString().split('T')[0] 
                             : 'TBA';
                             
                        return _buildEventCard(
                          context, 
                          id: event['id'].toString(),
                          title: event['title'] ?? 'Upcoming Event', 
                          date: dateStr, 
                          location: event['location'] ?? 'TBA', 
                          ptsLabel: 'Earn ' + (event['points_for_attending']?.toString() ?? '0') + ' pts',
                          imageUrl: event['image_url'],
                          onRsvp: () => _handleRsvp(event['id'].toString()),
                          onRefer: () => _handleRefer(event['id'].toString()),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, {required String id, required String title, required String date, required String location, required String ptsLabel, String? imageUrl, required VoidCallback onRsvp, required VoidCallback onRefer}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.inputFill),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
                          child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image_rounded, size: 50, color: AppColors.textSecondary))),
                        )
                      : const Center(child: Icon(Icons.image_outlined, size: 50, color: AppColors.textSecondary)),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: PointsBadge(points: ptsLabel),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(date, style: AppTextStyles.labelSmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(child: Text(location, style: AppTextStyles.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                       Expanded(
                         child: ElevatedButton(
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primaryGold,
                             foregroundColor: AppColors.backgroundBase,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                           onPressed: onRsvp,
                           child: const Text('RSVP Now', style: TextStyle(fontWeight: FontWeight.bold)),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: OutlinedButton(
                           style: OutlinedButton.styleFrom(
                             foregroundColor: AppColors.primaryGold,
                             side: const BorderSide(color: AppColors.primaryGold),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                           onPressed: onRefer,
                           child: const Text('Refer a Friend'),
                         ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Profile ----------------- //
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userProfile;

  // Controllers for editable fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _homeOwnershipCtrl = TextEditingController();
  final _annualIncomeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _genderCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postcodeCtrl.dispose();
    _industryCtrl.dispose();
    _homeOwnershipCtrl.dispose();
    _annualIncomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getMe();
      if (res['success']) {
        _userProfile = res['data'];
        _nameCtrl.text = _userProfile?['full_name'] ?? '';
        _emailCtrl.text = _userProfile?['email'] ?? '';
        _mobileCtrl.text = _userProfile?['mobile'] ?? '';
        _genderCtrl.text = _userProfile?['gender'] ?? '';
        _addressCtrl.text = _userProfile?['street_address'] ?? '';
        _cityCtrl.text = _userProfile?['city'] ?? '';
        _stateCtrl.text = _userProfile?['state'] ?? '';
        _postcodeCtrl.text = _userProfile?['postal_code'] ?? '';
        _industryCtrl.text = _userProfile?['industry'] ?? '';
        _homeOwnershipCtrl.text = _userProfile?['home_ownership'] ?? '';
        _annualIncomeCtrl.text = _userProfile?['annual_income'] ?? '';
      }
    } catch (e) {
      debugPrint("Profile Error: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final result = await _apiService.updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'street_address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'postal_code': _postcodeCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
        'home_ownership': _homeOwnershipCtrl.text.trim(),
        'annual_income': _annualIncomeCtrl.text.trim(),
      });

      if (mounted) {
        if (result['success']) {
          setState(() {
            _userProfile = result['data'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to save', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Account',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone. All your data, points, and referrals will be deleted permanently.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                setState(() => _isSaving = true);
                final res = await _apiService.deleteAccount();
                setState(() => _isSaving = false);
                if (mounted) {
                  if (res['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account successfully deleted.', style: TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Log out and send to login screen
                    await _apiService.logout();
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting account: ${res['error']}', style: const TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _isLoading ? 
                const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.surfaceCard,
                      child: Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'U',
                        style: const TextStyle(color: AppColors.primaryGold, fontSize: 32, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User Name', style: AppTextStyles.h2),
                    Text('Gold Member', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold)),
                    const SizedBox(height: 32),
                    
                    // Form
                    DarkTextField(hint: 'Full Name', controller: _nameCtrl, keyboardType: TextInputType.name),
                    const SizedBox(height: 16),
                    DarkTextField(hint: 'Email Address', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, isLocked: true),
                    const SizedBox(height: 16),
                    DarkTextField(hint: 'Mobile Number', controller: _mobileCtrl, keyboardType: TextInputType.phone),
                  ]
              ),
            const SizedBox(height: 32),
            
            Text('Personal Details', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            DarkDropdownField(
              hint: 'Select Gender (Optional)',
              value: _genderCtrl.text.isNotEmpty ? _genderCtrl.text : null,
              items: const ['Male', 'Female', 'Non-Binary', 'Other', 'Prefer not to say'],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _genderCtrl.text = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DarkTextField(hint: 'Street Address', controller: _addressCtrl),
            const SizedBox(height: 16),
            Row(
              children: [
                 Expanded(child: DarkTextField(hint: 'City', controller: _cityCtrl)),
                 const SizedBox(width: 16),
                 Expanded(child: DarkTextField(hint: 'State', controller: _stateCtrl)),
              ],
            ),
            const SizedBox(height: 16),
            DarkTextField(hint: 'Postcode', controller: _postcodeCtrl, keyboardType: TextInputType.number),
            
            const SizedBox(height: 32),
            Text('Professional Details', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            DarkTextField(hint: 'Industry', controller: _industryCtrl),
            const SizedBox(height: 16),
            DarkDropdownField(
              hint: 'Select Occupancy / Home Ownership',
              value: _homeOwnershipCtrl.text.isNotEmpty ? _homeOwnershipCtrl.text : null,
              items: const ['Owner Occupier', 'Mortgage', 'Renting', 'Living with Family', 'Other'],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _homeOwnershipCtrl.text = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DarkTextField(hint: 'Annual Income Range', controller: _annualIncomeCtrl),
            
            const SizedBox(height: 48),
            _isSaving
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : GoldButton(text: 'Save Details', onPressed: _saveProfile),
            const SizedBox(height: 24),
            OutlinedButton(
               style: OutlinedButton.styleFrom(
                 foregroundColor: AppColors.error,
                 side: const BorderSide(color: AppColors.error),
                 minimumSize: const Size(double.infinity, 50),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusButton)),
               ),
               onPressed: () async {
                 // Trigger API Logout
                 await _apiService.logout();
                 if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                 }
               },
               child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showDeleteAccountConfirmation,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ----------------- QR Scanner ----------------- //
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
       final code = barcodes.first.rawValue!;
       setState(() => _isProcessing = true);
       
       final res = await _apiService.scanEventAttendance(code);
       
       if (mounted) {
          Navigator.pop(context); // Close scanner
          if (res['success']) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points Received! Attendance Confirmed.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Invalid QR Code', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
          }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Event QR'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          if (_isProcessing)
             const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
          Positioned(
             bottom: 40,
             left: 0,
             right: 0,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                 child: const Text('Align QR code within frame', style: TextStyle(color: Colors.white)),
               ),
             ),
          ),
        ],
      ),
    );
  }
}

class DarkDropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const DarkDropdownField({
    Key? key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGold),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
