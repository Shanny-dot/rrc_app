import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/core_widgets.dart';
import 'dashboard_screens.dart';
import '../services/api_service.dart';

// ----------------- Auth flow ----------------- //

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
     super.initState();
     _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
     await Future.delayed(const Duration(seconds: 2));
     
     try {
       final api = ApiService();
       final hasToken = await api.isLoggedIn();
       
       if (hasToken) {
          // Ping backend to ensure token is still valid (timeout after 10s to prevent getting stuck)
          final res = await api.getMe().timeout(const Duration(seconds: 10));
          if (res['success']) {
             if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainAppScaffold()));
             }
             return;
          }
       }
     } catch (e) {
       debugPrint("Auth check failed or timed out: $e");
     }
     
     // Fallback to Quick Sign Up if no token, token is deeply expired, or network error occurs
     if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuickSignUpScreen()));
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/rrc_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text('EXCLUSIVE REWARDS', style: AppTextStyles.labelMedium.copyWith(letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

class QuickSignUpScreen extends StatefulWidget {
  const QuickSignUpScreen({Key? key}) : super(key: key);

  @override
  State<QuickSignUpScreen> createState() => _QuickSignUpScreenState();
}

class _QuickSignUpScreenState extends State<QuickSignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Country code selector — default Australia
  String _countryCode = '+61';
  final List<Map<String, String>> _countryCodes = [
    {'flag': '🇦🇺', 'code': '+61', 'name': 'Australia'},
    {'flag': '🇮🇳', 'code': '+91', 'name': 'India'},
    {'flag': '🇺🇸', 'code': '+1',  'name': 'USA'},
    {'flag': '🇬🇧', 'code': '+44', 'name': 'UK'},
    {'flag': '🇳🇿', 'code': '+64', 'name': 'New Zealand'},
    {'flag': '🇸🇬', 'code': '+65', 'name': 'Singapore'},
  ];

  String get _fullMobile => '$_countryCode${_mobileController.text.trim()}';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Prepare demo data that satisfies the DB schema
    final payload = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _fullMobile,   // already E.164 — e.g. +61412345678
      'password': _passwordController.text.trim(),
    };

    try {
      final api = ApiService();
      final result = await api.register(payload);

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OTPVerificationScreen(mobileNumber: _fullMobile)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration Failed: ' + (result["error"] ?? 'Unknown Error'))),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App Error: \${e.toString()}')),
        );
      }
    }
  }

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
              
              DarkTextField(hint: 'Full Name', controller: _nameController),
              const SizedBox(height: AppDimens.sectionGap),
              DarkTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress, controller: _emailController),
              const SizedBox(height: AppDimens.sectionGap),

              // ── Country code + phone number row ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Country code dropdown
                    PopupMenuButton<String>(
                      color: AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) => setState(() => _countryCode = val),
                      itemBuilder: (_) => _countryCodes.map((c) => PopupMenuItem<String>(
                        value: c['code'],
                        child: Text(
                          '${c["flag"]}  ${c["name"]} (${c["code"]})',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      )).toList(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Row(
                          children: [
                            Text(
                              '${_countryCodes.firstWhere((c) => c["code"] == _countryCode)["flag"]}  $_countryCode',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    // Vertical divider
                    Container(width: 1, height: 24, color: AppColors.textSecondary.withOpacity(0.3)),
                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.sectionGap),
              DarkTextField(hint: 'Password', obscureText: true, controller: _passwordController),
              
              const Spacer(),
              
              GoldButton(
                text: _isLoading ? 'Creating...' : 'Create Account',
                onPressed: _isLoading ? () {} : _handleSignup,
              ),
              const SizedBox(height: 16),
              Center(
                child: GoldButton(
                  text: 'Already have an account? Login',
                  isTextLink: true,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
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

class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;

  const OTPVerificationScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _mobileCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccount() async {
    // The code should theoretically come from the 6 boxes, 
    // but we can just use the controller or combine the boxes.
    // Let's assume there is a single text field instead for simplicity, 
    // or we can read from the individual boxes. 
    // Wait, the UI has 6 individual boxes but they aren't wired up to a single controller.
    // Let's modify the UI to use a single DarkTextField for the Mobile OTP for easier testing.
    
    if (_mobileCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the mobile OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final api = ApiService();
    final result = await api.verifyMobile(widget.mobileNumber, _mobileCodeController.text);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeBonusScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: ${result["error"]}')),
        );
      }
    }
  }

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
                      Text('Sent to ' + widget.mobileNumber, style: AppTextStyles.labelSmall),
                      const SizedBox(height: 16),
                      // Replace the 6 dummy boxes with a single input for easier integration
                      DarkTextField(
                        hint: 'Enter 6-digit mobile code', 
                        keyboardType: TextInputType.number, 
                        textAlign: TextAlign.center,
                        controller: _mobileCodeController,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sending new code...')),
                            );
                            final api = ApiService();
                            final res = await api.resendOTP(widget.mobileNumber);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['success'] ? 'New code sent!' : 'Failed: ${res["error"]}')),
                              );
                            }
                          },
                          child: Text('Resend code', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGold)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              GoldButton(
                text: _isLoading ? 'Verifying...' : 'Verify & Continue',
                onPressed: _isLoading ? () {} : _verifyAccount,
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
  String _firstName = 'User';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final api = ApiService();
      final res = await api.getMe();
      if (res['success'] && res['data'] != null) {
        final fullName = res['data']['full_name'] as String? ?? 'User';
        if (mounted) {
          setState(() {
            _firstName = fullName.split(' ').first;
            _isLoadingName = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingName = false);
    }
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
              _isLoadingName 
                  ? const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(color: AppColors.primaryGold))
                  : Text('Welcome, $_firstName', style: AppTextStyles.h2),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final api = ApiService();
      final result = await api.login(_emailController.text.trim(), _passwordController.text.trim());

      if (mounted) setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainAppScaffold()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Failed: ${result["error"]}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome Back', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('Enter your credentials to continue.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),
              
              DarkTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress, controller: _emailController),
              const SizedBox(height: AppDimens.sectionGap),
              DarkTextField(hint: 'Password', obscureText: true, controller: _passwordController, isLocked: false),
              
              const Spacer(),
              
              GoldButton(
                text: _isLoading ? 'Logging in...' : 'Login',
                onPressed: _isLoading ? () {} : _handleLogin,
              ),
              const SizedBox(height: 16),
              Center(
                child: GoldButton(
                  text: "Don't have an account? Sign Up",
                  isTextLink: true,
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const QuickSignUpScreen()),
                      );
                    }
                  },
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
