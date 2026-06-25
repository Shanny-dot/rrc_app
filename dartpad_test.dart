import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

void main() {
  runApp(const RRCApp());
}

// ----------------- Design System Tokens ----------------- //

class AppColors {
  // Backgrounds
  static const Color backgroundBase = Color(0xFF0A0A0A);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color inputFill = Color(0xFF222222);
  
  // Accents
  static const Color primaryGold = Color(0xFFFAB95B);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  
  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
}

class AppDimens {
  static const double gridBase = 8.0;
  static const double pageMargin = 20.0;
  static const double sectionGap = 24.0;
  
  // Radii
  static const double radiusCard = 16.0;
  static const double radiusInput = 10.0;
  static const double radiusButton = 28.0;
  static const double radiusPill = 99.0;
}

class AppTextStyles {
  // Headings (Bold)
  static TextStyle h1 = GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle h2 = GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle h3 = GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  
  // Labels (Medium)
  static TextStyle labelLarge = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle labelMedium = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle labelSmall = GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  
  // Body (Regular)
  static TextStyle bodyLarge = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
  static TextStyle bodyMedium = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGold,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGold,
        secondary: AppColors.primaryGold,
        surface: AppColors.surfaceCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
      ),
    );
  }
}

class RRCApp extends StatelessWidget {
  const RRCApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RRC - Luxury Rewards',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ----------------- Reusable Components ----------------- //

class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isTextLink;

  const GoldButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isTextLink = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isTextLink) {
      return TextButton(
        onPressed: onPressed,
        child: Text(text, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : AppColors.primaryGold,
          foregroundColor: isSecondary ? AppColors.primaryGold : AppColors.backgroundBase,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
            side: isSecondary 
                ? const BorderSide(color: AppColors.primaryGold, width: 1.5)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSecondary ? AppColors.primaryGold : AppColors.backgroundBase,
          ),
        ),
      ),
    );
  }
}

class DarkTextField extends StatelessWidget {
  final String hint;
  final bool isLocked;
  final TextInputType keyboardType;
  final String? initialValue;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextAlign textAlign;

  const DarkTextField({
    Key? key,
    required this.hint,
    this.isLocked = false,
    this.keyboardType = TextInputType.text,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: isLocked,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium,
        prefixIcon: prefixIcon,
        suffixIcon: isLocked 
            ? const Icon(Icons.lock_rounded, color: AppColors.primaryGold, size: 20)
            : suffixIcon,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
        ),
      ),
    );
  }
}

class PointsBadge extends StatelessWidget {
  final String points;
  final bool isLarge;

  const PointsBadge({Key? key, required this.points, this.isLarge = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 16 : 10, vertical: isLarge ? 8 : 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: isLarge ? 18 : 14, color: AppColors.primaryGold),
          const SizedBox(width: 4),
          Text(
            points,
            style: TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Auth flow ----------------- //

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Auto navigate to Quick Sign Up for demo purposes
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuickSignUpScreen()));
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, size: 80, color: AppColors.primaryGold),
            ),
            const SizedBox(height: 24),
            Text('R R C', style: AppTextStyles.h1.copyWith(letterSpacing: 4)),
            const SizedBox(height: 8),
            Text('EXCLUSIVE REWARDS', style: AppTextStyles.labelMedium.copyWith(letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

class QuickSignUpScreen extends StatelessWidget {
  const QuickSignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join the Exclusive', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('Enter your details to request access.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),
              
              const DarkTextField(hint: 'Full Name'),
              const SizedBox(height: AppDimens.sectionGap),
              const DarkTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppDimens.sectionGap),
              const DarkTextField(hint: 'Mobile Number', keyboardType: TextInputType.phone),
              
              const Spacer(),
              
              GoldButton(
                text: 'Create Account',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPVerificationScreen()));
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: GoldButton(
                  text: 'Already have an account? Login',
                  isTextLink: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class OTPVerificationScreen extends StatelessWidget {
  const OTPVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verification', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('Please verify your mobile and email.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mobile OTP', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Text('Sent to +61 ••• ••• 234', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) => _buildOTPBox(context, index == 0)),
                      ),
                      const SizedBox(height: 16),
                      Center(child: Text('Resend code in 45s', style: AppTextStyles.labelMedium)),
                      
                      const SizedBox(height: 48),
                      
                      Text('Email OTP', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Text('Sent to jo••••@email.com', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 16),
                      const DarkTextField(hint: 'Enter 6-digit email code', keyboardType: TextInputType.number, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(child: Text('Resend code in 45s', style: AppTextStyles.labelMedium)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              GoldButton(
                text: 'Verify & Continue',
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeBonusScreen()));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(BuildContext context, bool isActive) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppDimens.radiusInput),
        border: Border.all(
          color: isActive ? AppColors.primaryGold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.h3,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class WelcomeBonusScreen extends StatefulWidget {
  const WelcomeBonusScreen({Key? key}) : super(key: key);

  @override
  _WelcomeBonusScreenState createState() => _WelcomeBonusScreenState();
}

class _WelcomeBonusScreenState extends State<WelcomeBonusScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGold.withOpacity(0.1),
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star_rounded, size: 60, color: AppColors.primaryGold),
                      const SizedBox(height: 16),
                      Text('+100', style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 48)),
                      Text('POINTS EARNED', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text('Welcome, Jordan', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('You\'ve successfully verified your account and earned your first reward points.', 
                style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
              const Spacer(),
              GoldButton(
                text: 'Go to Dashboard',
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainAppScaffold()));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

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
        decoration: BoxDecoration(
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
class DashboardTab extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const DashboardTab({Key? key, required this.onNavigateToTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceCard,
                child: Text('JS', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning,', style: AppTextStyles.labelSmall),
                Text('Jordan', style: AppTextStyles.labelLarge),
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
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        children: [
          // Profile Banner
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: Container(
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
          const SizedBox(height: AppDimens.sectionGap),

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
                Text('2,450', style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 40)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gold Tier', style: AppTextStyles.labelLarge),
                    Text('550 to Platinum', style: AppTextStyles.labelSmall),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.8,
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
              _buildQuickAction(Icons.person_add_rounded, 'Refer Friend', () => onNavigateToTab(1)),
              const SizedBox(width: 12),
              _buildQuickAction(Icons.card_giftcard_rounded, 'Redeem', () => onNavigateToTab(2)),
              const SizedBox(width: 12),
              _buildQuickAction(Icons.event_rounded, 'Events', () => onNavigateToTab(3)),
            ],
          ),
          const SizedBox(height: 32),

          Text('Recent Activity', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          
          _buildActivityRow(Icons.person_add_rounded, 'Referred Sarah J.', '2 hrs ago', '+100', true),
          _buildActivityRow(Icons.card_giftcard_rounded, 'Redeemed Movie Tkts', 'Yesterday', '-500', false),
          _buildActivityRow(Icons.check_circle_rounded, 'Referral Approved', '2 days ago', '+500', true),
        ],
      ),
    );
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
class ReferralsTab extends StatelessWidget {
  const ReferralsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        children: [
          Center(
            child: Column(
              children: [
                Text('Total Earned', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('800', style: AppTextStyles.h1.copyWith(color: AppColors.primaryGold, fontSize: 40)),
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
                  () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Text('Referral History', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          
          _buildHistoryRow('Michael Chen', 'Approved', '+500', AppColors.success),
          _buildHistoryRow('Sarah Johnson', 'Pending', '0', AppColors.primaryGold),
          _buildHistoryRow('David Smith', 'Registered', '+100', AppColors.success),
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
            child: Text(name[0], style: TextStyle(color: AppColors.textPrimary)),
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

class ReferFormScreen extends StatelessWidget {
  const ReferFormScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer a Friend')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        child: Column(
          children: [
            const DarkTextField(hint: 'Full Name'),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Mobile Number', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress),
            const Spacer(),
            GoldButton(text: 'Send Referral', onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ----------------- Rewards ----------------- //
class RewardsTab extends StatelessWidget {
  const RewardsTab({Key? key}) : super(key: key);

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
            child: GridView.builder(
              padding: const EdgeInsets.all(AppDimens.pageMargin),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildRewardCard(
                  context,
                  title: index == 0 ? 'VIP Movie Tickets' : (index == 1 ? 'Weekend Resort' : (index == 2 ? 'Fine Dining ' : 'Spa Package')),
                  points: index == 0 ? '100 pts' : (index == 1 ? '1,000 pts' : (index == 2 ? '500 pts' : '300 pts')),
                );
              },
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

  Widget _buildRewardCard(BuildContext context, {required String title, required String points}) {
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
              decoration: const BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
              ),
              child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 40)),
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
                         _showRedeemBottomSheet(context, title, points);
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
  
  void _showRedeemBottomSheet(BuildContext context, String title, String pts) {
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
                  Text(title, style: AppTextStyles.labelLarge),
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
              GoldButton(text: 'Confirm Redeem', onPressed: () {
                Navigator.pop(context);
                // Show success screen...
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
class EventsTab extends StatelessWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pageMargin),
              children: [
                _buildEventCard(context, 'Luxury Car Gala', '15 Oct', 'Crown Sydney', 'Earn 200 pts'),
                const SizedBox(height: 20),
                _buildEventCard(context, 'Private Wine Tasting', '22 Nov', 'Barossa Valley', 'Earn 100 pts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, String title, String date, String location, String ptsLabel) {
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
                  decoration: const BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
                  ),
                  child: const Center(child: Icon(Icons.image_outlined, size: 50, color: AppColors.textSecondary)),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(location, style: AppTextStyles.labelSmall),
                          ],
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
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pageMargin),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surfaceCard,
              child: Text('JS', style: TextStyle(fontSize: 36, color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text('Jordan Smith', style: AppTextStyles.h2),
            Text('Gold Member', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
            
            const SizedBox(height: 48),
            
            const DarkTextField(hint: 'Date of Birth', initialValue: '15 / 06 / 1995', isLocked: true),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Country', initialValue: 'Australia', isLocked: true),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Mobile Number', initialValue: '+61 400 000 000', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Email Address', initialValue: 'jordan@email.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 32),
            
            Text('Personal Details', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Gender (Optional)', initialValue: 'Male'),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Address Line 1', initialValue: '123 Fake Street'),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Address Line 2 (Optional)'),
            const SizedBox(height: 16),
            Row(
              children: const [
                 Expanded(child: DarkTextField(hint: 'City', initialValue: 'Sydney')),
                 SizedBox(width: 16),
                 Expanded(child: DarkTextField(hint: 'State', initialValue: 'NSW')),
              ],
            ),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Postcode', initialValue: '2000', keyboardType: TextInputType.number),
            
            const SizedBox(height: 32),
            Text('Professional Details', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Industry', initialValue: 'Technology'),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Home Ownership Status', initialValue: 'Renting'),
            const SizedBox(height: 16),
            const DarkTextField(hint: 'Annual Income Range', initialValue: '\$100,000 - \$150,000'),
            
            const SizedBox(height: 48),
            GoldButton(text: 'Save Details', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
