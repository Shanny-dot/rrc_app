import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import 'registration_step_2.dart';

class RegistrationStep1 extends StatefulWidget {
  const RegistrationStep1({Key? key}) : super(key: key);

  @override
  State<RegistrationStep1> createState() => _RegistrationStep1State();
}

class _RegistrationStep1State extends State<RegistrationStep1> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  String? _selectedIndustry;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Basic validation
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Pass data forward
    final data = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'dob': _dobController.text,
      'gender': _selectedGender,
      'industry': _selectedIndustry,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationStep2(registrationData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), 
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
                    'Step 1 of 3 ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Personal Information',
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
                        label: 'First Name',
                        isRequired: true,
                        controller: _firstNameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Last Name',
                        isRequired: true,
                        controller: _lastNameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Date of Birth',
                        isRequired: true,
                        keyboardType: TextInputType.datetime,
                        controller: _dobController,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown(
                        label: 'Gender',
                        isRequired: true,
                        items: const ['Male', 'Female', 'Other', 'Prefer not to say'],
                        value: _selectedGender,
                        onChanged: (val) {
                          setState(() {
                            _selectedGender = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown(
                        label: 'Industry',
                        isRequired: true,
                        items: const ['Technology', 'Finance', 'Healthcare', 'Education', 'Other'],
                        value: _selectedIndustry,
                        onChanged: (val) {
                          setState(() {
                            _selectedIndustry = val;
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
                      text: 'Cancel',
                      isPrimary: false,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Next',
                      onPressed: _nextStep,
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
