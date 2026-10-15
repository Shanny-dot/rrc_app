import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/app_lock.dart';
import 'auth_flow.dart' show LoginScreen;
import '../theme/app_theme.dart';
import '../widgets/core_widgets.dart';
import '../widgets/ui_kit.dart';
import 'redesign/home_tab.dart';
import 'redesign/referrals_tab.dart';
import 'redesign/rewards_tab.dart';
import 'redesign/events_tab.dart';
import 'redesign/help_screen.dart';

// The redesigned screens live in screens/redesign/. Re-exported so existing imports keep working.
export 'redesign/home_tab.dart';
export 'redesign/referrals_tab.dart';
export 'redesign/rewards_tab.dart';
export 'redesign/events_tab.dart';
export 'redesign/profile_screen.dart';
export 'redesign/help_screen.dart';
export 'redesign/welcome_tour.dart';
export 'redesign/loan_checkin_screen.dart';
export 'redesign/notification_settings_screen.dart';

// ----------------- Main Navigation Layout ----------------- //

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({Key? key}) : super(key: key);

  @override
  _MainAppScaffoldState createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _leftAt;
  bool _lockShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-lock with Face ID / fingerprint when the member returns after a few minutes away.
  // (The biometric prompt itself pauses the app, so ignore lifecycle changes while it's up.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (AppLock.isAuthenticating || _lockShowing) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final leftAt = _leftAt;
      _leftAt = null;
      if (leftAt == null || DateTime.now().difference(leftAt) < AppLock.relockAfter || !await AppLock.isEnabled()) return;
      if (!mounted) return;
      _lockShowing = true;
      await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (lockContext) => AppLockScreen(
          onUnlocked: () => Navigator.pop(lockContext),
          onUsePassword: () async {
            await ApiService().logout();
            if (lockContext.mounted) {
              Navigator.of(lockContext, rootNavigator: true)
                  .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            }
          },
        ),
      ));
      _lockShowing = false;
    }
  }

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
            BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_outlined), activeIcon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_alt_rounded), label: 'Referrals'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_outlined), activeIcon: Icon(Icons.card_giftcard_rounded), label: 'Rewards'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_month_rounded), label: 'Events'),
          ],
        ),
      ),
    );
  }
}

// ----------------- Refer a friend (manual details) ----------------- //
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
  final _notesController = TextEditingController();
  bool _consent = false;
  bool _isLoading = false;
  String? _error;

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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final email = _emailController.text.trim();

    String? problem;
    if (name.isEmpty) {
      problem = 'Please enter your friend\'s name.';
    } else if (phone.isEmpty && email.isEmpty) {
      problem = 'Please enter a mobile number or email address.';
    } else if (phone.isNotEmpty && !RegExp(r'^(?:\+?61|0)?4\d{8}$').hasMatch(phone)) {
      problem = 'Please enter a valid Australian mobile number (e.g. 0412 345 678).';
    } else if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      problem = 'Please enter a valid email address.';
    } else if (!_consent) {
      problem = 'Please confirm your friend is happy to be contacted.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await ApiService().submitReferral({
      'referred_name': name,
      if (phone.isNotEmpty) 'referred_mobile': phone,
      if (email.isNotEmpty) 'referred_email': email,
      'channel': widget.initialName != null ? 'contacts' : 'form',
      'consent_given': true,
      if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      final contact = await ProgramContact.load();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('Thank you!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('We\'ve added $name to your referrals. A Reliance broker will contact them, '
                  'and you can follow their progress on the Referrals screen.'),
              const SizedBox(height: 18),
              Text('Want to talk it through with your broker?', style: AppTextStyles.labelMedium),
              const SizedBox(height: 10),
              BrokerActions(info: contact, emailSubject: 'About my referral of $name'),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done', style: TextStyle(color: AppColors.primaryGold)))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _error = (res['error'] ?? 'Submission failed').toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer a friend')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          children: [
            Text('Tell us who to contact. A Reliance broker will reach out to see how they can help.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            LabeledField(label: 'Friend\'s name', child: DarkTextField(hint: 'Full name', controller: _nameController)),
            const SizedBox(height: 14),
            LabeledField(label: 'Mobile', child: DarkTextField(hint: '04XX XXX XXX', keyboardType: TextInputType.phone, controller: _phoneController)),
            const SizedBox(height: 14),
            LabeledField(label: 'Email', child: DarkTextField(hint: 'name@example.com', keyboardType: TextInputType.emailAddress, controller: _emailController)),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Notes (optional)',
              child: DarkTextField(hint: 'e.g. best time to call, what they need help with', controller: _notesController),
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
                    child: Text('My friend is happy to be contacted by Reliance about their home loan.', style: AppTextStyles.bodyMedium),
                  ),
                ),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : GoldButton(text: 'Send referral', onPressed: _submit),
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
