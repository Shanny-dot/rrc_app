import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../services/api_service.dart';
import 'verification_screen.dart';

class RegistrationStep3 extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const RegistrationStep3({Key? key, required this.registrationData}) : super(key: key);

  @override
  State<RegistrationStep3> createState() => _RegistrationStep3State();
}

class _RegistrationStep3State extends State<RegistrationStep3> {
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _homeOwnership;
  String? _annualIncome;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_mobileController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final finalData = Map<String, dynamic>.from(widget.registrationData)
      ..addAll({
        'mobile_number': _mobileController.text,
        'email': _emailController.text,
        'password': _passwordController.text, // Sending password securely via HTTPS POST
        'home_ownership_status': _homeOwnership,
        'annual_income': _annualIncome,
      });

    final api = ApiService();
    final result = await api.register(finalData);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Navigate to Verification
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificationScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: \${result["error"]}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: AppColors.primaryBlue),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Step Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: const [
                  Text(
                    'Step 3 of 3 ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Contact & Financial',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.primaryBlueDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Mobile Number',
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        controller: _mobileController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Email Address',
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Create a Password',
                        isRequired: true,
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown(
                        label: 'Home Ownership',
                        isRequired: true,
                        items: const ['Own Outright', 'Mortgage', 'Renting', 'Living with parents', 'Other'],
                        value: _homeOwnership,
                        onChanged: (val) {
                          setState(() {
                            _homeOwnership = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown(
                        label: 'Annual Income (AUD)',
                        isRequired: true,
                        items: const ['Under \$50k', '\$50k - \$100k', '\$100k - \$150k', 'Over \$150k'],
                        value: _annualIncome,
                        onChanged: (val) {
                          setState(() {
                            _annualIncome = val;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Back',
                      isPrimary: false,
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _isLoading ? 'Submitting...' : 'Submit',
                      onPressed: _isLoading ? null : () {
                        _submitRegistration();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
