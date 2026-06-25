import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({Key? key}) : super(key: key);

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Text(
                'We\'ve sent verification codes to your mobile and email. Please enter them below to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryBlue,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SMS Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: const [
                          Text(
                            'SMS Verification ',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.primaryBlueDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Enter 6-digit code sent to +61 ••• ••• 234',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 6 boxes for OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) => _buildOTPBox(context)),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Resend code in 55s',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: const [
                          Text(
                            'Email Verification ',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.primaryBlueDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Enter code sent to jo••••@email.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const CustomTextField(
                        label: 'Email Verification Code',
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Resend code in 55s',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Button
              CustomButton(
                text: 'Verify & Continue',
                // Using a greyish styling to match the screenshot feeling of disabled/unfilled state
                backgroundColor: const Color(0xFFC8C2BB), 
                textColor: AppColors.textGrey,
                onPressed: () {
                  // After verification, likely go to Home/Dashboard
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(BuildContext context) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 20, color: AppColors.primaryBlueDark, fontWeight: FontWeight.bold),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
