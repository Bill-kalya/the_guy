import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final void Function(String)? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '0712345678',
        prefixIcon: const Icon(Icons.phone_android),
        prefixText: '+254 ',
        errorText: errorText,
        helperText: 'Enter your Kenyan phone number',
      ),
      onChanged: onChanged,
      validator: (value) => Validators.validatePhoneNumber(value),
    );
  }
}
