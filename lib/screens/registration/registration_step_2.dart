import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import 'registration_step_3.dart';

class RegistrationStep2 extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const RegistrationStep2({Key? key, required this.registrationData}) : super(key: key);

  @override
  State<RegistrationStep2> createState() => _RegistrationStep2State();
}

class _RegistrationStep2State extends State<RegistrationStep2> {
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  String? _selectedState;

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_streetController.text.isEmpty || _cityController.text.isEmpty || _postalController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Merge data from previous step
    final updatedData = Map<String, dynamic>.from(widget.registrationData)
      ..addAll({
        'address_line1': _streetController.text,
        'city': _cityController.text,
        'state_region': _selectedState,
        'postal_code': _postalController.text,
        'country': 'Australia', // Hardcoded as per UI
      });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationStep3(registrationData: updatedData),
      ),
    );
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
                    'Step 2 of 3 ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Address Details',
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
                        label: 'Street Address',
                        isRequired: true,
                        controller: _streetController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'City',
                        isRequired: true,
                        controller: _cityController,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown(
                        label: 'State',
                        isRequired: true,
                        items: const ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'],
                        value: _selectedState,
                        onChanged: (val) {
                          setState(() {
                            _selectedState = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Postal Code',
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        controller: _postalController,
                      ),
                      const SizedBox(height: 16),
                      // Country (Locked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Country',
                            style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.textGrey.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Australia',
                                  style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                                ),
                                Icon(Icons.lock, color: AppColors.errorRed, size: 20),
                              ],
                            ),
                          ),
                        ],
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
