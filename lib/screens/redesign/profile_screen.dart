import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/app_lock.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/core_widgets.dart';
import '../../widgets/loading.dart';
import '../../widgets/ui_kit.dart';
import '../auth_flow.dart' show LoginScreen;
import 'feedback_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';

/// Drop-down options. Placeholder lists until Reliance confirms the official ones —
/// keep the values in step with the admin website.
class ProfileOptions {
  static const genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  static const states = ['ACT', 'NSW', 'NT', 'QLD', 'SA', 'TAS', 'VIC', 'WA'];
  static const industries = [
    'Accounting & Finance', 'Construction & Trades', 'Education', 'Government', 'Healthcare',
    'Hospitality & Tourism', 'Information Technology', 'Legal', 'Manufacturing', 'Real Estate',
    'Retail', 'Self-employed / Business owner', 'Transport & Logistics', 'Retired', 'Other',
  ];
  static const homeOwnership = ['Own outright', 'Own with a mortgage', 'Renting', 'Living with family', 'Other'];
  static const incomes = [
    'Under \$50,000', '\$50,000 – \$100,000', '\$100,000 – \$150,000', '\$150,000 – \$200,000', '\$200,000 – \$300,000',
    'Over \$300,000', 'Prefer not to say',
  ];

  /// Maps values typed into the old free-text fields to the new options.
  static String? normalise(String? raw, List<String> options) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();
    for (final o in options) {
      if (o.toLowerCase() == v.toLowerCase()) return o;
    }
    final l = v.toLowerCase().replaceAll(RegExp(r'[\s,\$]'), '');
    if (identical(options, homeOwnership)) {
      if (l.contains('mortgag')) return 'Own with a mortgage';
      if (l.contains('owner') || l.contains('outright') || l == 'own') return 'Own outright';
      if (l.contains('rent')) return 'Renting';
      if (l.contains('family') || l.contains('parent')) return 'Living with family';
    }
    if (identical(options, genders) && (l == 'non-binary' || l == 'nonbinary')) return 'Non-binary';
    if (identical(options, incomes)) {
      const map = {
        '0-50000': 'Under \$50,000', '<50000': 'Under \$50,000', 'under50000': 'Under \$50,000',
        '50000-100000': '\$50,000 – \$100,000', '100000-150000': '\$100,000 – \$150,000',
        '150000-200000': '\$150,000 – \$200,000', '200000-300000': '\$200,000 – \$300,000',
        '300000+': 'Over \$300,000', 'over300000': 'Over \$300,000',
      };
      final key = l.replaceAll('–', '-');
      if (map.containsKey(key)) return map[key];
    }
    if (identical(options, industries) && l.contains('financ')) return 'Accounting & Finance';
    return null;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _suburbCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _state;
  String? _industry;
  String? _homeOwnership;
  String? _income;
  String _referralCode = '';

  bool _lockAvailable = false;
  bool _lockEnabled = false;
  String _lockLabel = 'Face ID';

  @override
  void initState() {
    super.initState();
    _load();
    _loadLock();
  }

  Future<void> _loadLock() async {
    final available = await AppLock.isAvailable();
    final enabled = await AppLock.isEnabled();
    final label = await AppLock.label();
    if (!mounted) return;
    setState(() {
      _lockAvailable = available;
      _lockEnabled = enabled;
      _lockLabel = label;
    });
  }

  Future<void> _toggleLock(bool on) async {
    // Confirm with the biometric itself before turning it on, so members can't lock themselves out.
    if (on && !await AppLock.authenticate("Confirm it's you to turn on $_lockLabel")) return;
    await AppLock.setEnabled(on);
    if (mounted) setState(() => _lockEnabled = on);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _mobileCtrl, _addressCtrl, _suburbCtrl, _postcodeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getMe();
      if (res['success']) {
        final p = Map<String, dynamic>.from(res['data']);
        _nameCtrl.text = (p['full_name'] ?? '').toString();
        _emailCtrl.text = (p['email'] ?? '').toString();
        _mobileCtrl.text = (p['mobile'] ?? '').toString();
        _addressCtrl.text = (p['street_address'] ?? '').toString();
        _suburbCtrl.text = (p['city'] ?? '').toString();
        _postcodeCtrl.text = (p['postal_code'] ?? '').toString();
        _dob = p['dob'] != null ? DateTime.tryParse(p['dob'].toString()) : null;
        _gender = ProfileOptions.normalise(p['gender']?.toString(), ProfileOptions.genders);
        _state = ProfileOptions.normalise(p['state']?.toString(), ProfileOptions.states);
        _industry = ProfileOptions.normalise(p['industry']?.toString(), ProfileOptions.industries);
        _homeOwnership = ProfileOptions.normalise(
            (p['home_ownership'] ?? p['home_ownership_status'])?.toString(), ProfileOptions.homeOwnership);
        _income = ProfileOptions.normalise(p['annual_income']?.toString(), ProfileOptions.incomes);
        _referralCode = (p['referral_code'] ?? '').toString();
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 35, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Date of birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primaryGold, onPrimary: AppColors.backgroundBase, surface: AppColors.surfaceCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final postcode = _postcodeCtrl.text.trim();
    if (postcode.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(postcode)) {
      showToast(context, 'Postcode should be 4 digits.', error: true);
      return;
    }
    setState(() => _isSaving = true);
    final payload = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      'mobile': _mobileCtrl.text.trim(),
      'street_address': _addressCtrl.text.trim(),
      'city': _suburbCtrl.text.trim(),
      'postal_code': postcode,
      if (_dob != null) 'dob': Fmt.isoDate(_dob!),
      if (_gender != null) 'gender': _gender,
      if (_state != null) 'state': _state,
      if (_industry != null) 'industry': _industry,
      if (_homeOwnership != null) 'home_ownership': _homeOwnership,
      if (_income != null) 'annual_income': _income,
    };
    final res = await _api.updateProfile(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    showToast(context, res['success'] ? 'Profile saved.' : (res['error'] ?? 'Failed to save').toString(), error: !res['success']);
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure? This permanently deletes your account, points and referrals and can\'t be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSaving = true);
              final res = await _api.deleteAccount();
              if (!mounted) return;
              setState(() => _isSaving = false);
              if (res['success']) {
                await _logout();
              } else {
                showToast(context, 'Error deleting account: ${res['error']}', error: true);
              }
            },
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(AppDimens.radiusInput)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value != null && items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(hint, style: AppTextStyles.bodyMedium),
          dropdownColor: AppColors.surfaceCard,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 4),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateField() {
    return GestureDetector(
      onTap: _pickDob,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(AppDimens.radiusInput)),
        child: Row(children: [
          Expanded(
            child: Text(_dob == null ? 'DD/MM/YYYY' : Fmt.dmy(_dob),
                style: _dob == null ? AppTextStyles.bodyMedium : const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ),
          const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _settingsTile({required IconData icon, required String title, required String subtitle, required Widget trailing, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
          leading: Icon(icon, color: AppColors.primaryGold),
          title: Text(title, style: AppTextStyles.labelLarge),
          subtitle: Text(subtitle, style: AppTextStyles.labelSmall),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: _isLoading
          ? const FriendlyLoader(message: 'Loading your profile…', layout: SkeletonLayout.form)
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 0, AppDimens.pageMargin, 24),
                      children: [
                        const SectionLabel('Account'),
                        LabeledField(label: 'Full name', child: DarkTextField(hint: 'Full name', controller: _nameCtrl, keyboardType: TextInputType.name)),
                        const SizedBox(height: 14),
                        LabeledField(label: 'Email', child: DarkTextField(hint: 'Email', controller: _emailCtrl, isLocked: true, keyboardType: TextInputType.emailAddress)),
                        const SizedBox(height: 14),
                        LabeledField(label: 'Mobile', child: DarkTextField(hint: '04XX XXX XXX', controller: _mobileCtrl, keyboardType: TextInputType.phone)),
                        if (_referralCode.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          LabeledField(
                            label: 'Your referral code',
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(AppDimens.radiusInput)),
                              child: Row(children: [
                                Expanded(child: Text(_referralCode, style: const TextStyle(color: AppColors.primaryGold, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
                              ]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const SectionLabel('Personal details'),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: LabeledField(label: 'Date of birth', child: _dateField())),
                          const SizedBox(width: 12),
                          Expanded(child: LabeledField(label: 'Gender', child: _dropdown('Select', _gender, ProfileOptions.genders, (v) => setState(() => _gender = v)))),
                        ]),
                        const SizedBox(height: 14),
                        LabeledField(label: 'Street address', child: DarkTextField(hint: 'Street address', controller: _addressCtrl)),
                        const SizedBox(height: 14),
                        LabeledField(label: 'Suburb', child: DarkTextField(hint: 'Suburb', controller: _suburbCtrl)),
                        const SizedBox(height: 14),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: LabeledField(label: 'State', child: _dropdown('Select', _state, ProfileOptions.states, (v) => setState(() => _state = v)))),
                          const SizedBox(width: 12),
                          Expanded(child: LabeledField(label: 'Postcode', child: DarkTextField(hint: '0000', controller: _postcodeCtrl, keyboardType: TextInputType.number))),
                        ]),
                        const SizedBox(height: 18),
                        const SectionLabel('Professional details'),
                        LabeledField(label: 'Industry', child: _dropdown('Select your industry', _industry, ProfileOptions.industries, (v) => setState(() => _industry = v))),
                        const SizedBox(height: 14),
                        LabeledField(label: 'Home ownership status', child: _dropdown('Select', _homeOwnership, ProfileOptions.homeOwnership, (v) => setState(() => _homeOwnership = v))),
                        const SizedBox(height: 14),
                        LabeledField(label: 'Annual income range', child: _dropdown('Select', _income, ProfileOptions.incomes, (v) => setState(() => _income = v))),
                        const SizedBox(height: 18),
                        const SectionLabel('Security & help'),
                        if (_lockAvailable)
                          _settingsTile(
                            icon: _lockLabel == 'Face ID' ? Icons.face_retouching_natural : Icons.fingerprint_rounded,
                            title: 'Unlock with $_lockLabel',
                            subtitle: 'Ask for $_lockLabel when you open the app',
                            trailing: Switch(value: _lockEnabled, activeThumbColor: AppColors.primaryGold, onChanged: _toggleLock),
                            onTap: () => _toggleLock(!_lockEnabled),
                          ),
                        _settingsTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Choose which phone alerts you get',
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                        ),
                        _settingsTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & contact',
                          subtitle: 'Common questions, program terms and privacy',
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
                        ),
                        _settingsTile(
                          icon: Icons.rate_review_outlined,
                          title: 'Send feedback',
                          subtitle: 'Ideas, problems or praise — we read every message',
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(AppDimens.pageMargin, 12, AppDimens.pageMargin, 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: UiColors.border))),
                    child: Column(children: [
                      SizedBox(
                        width: double.infinity,
                        child: _isSaving
                            ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)))
                            : GoldButton(text: 'Save details', onPressed: _save),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(onPressed: _logout, child: Text('Log out', style: AppTextStyles.labelLarge)),
                          TextButton(
                            onPressed: _confirmDelete,
                            child: Text('Delete account', style: AppTextStyles.labelLarge.copyWith(color: UiColors.red)),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }
}
