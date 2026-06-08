import 'package:flutter/material.dart';

// widget reusable mte3 text input
class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
  });

  // label eli yban fou9/dakhel input
  final String label;

  // hint optionnel yفسر chnowa user yekteb
  final String? hint;

  // controller bech naqraw wala nbadlou text
  final TextEditingController? controller;

  // validator bech nvalidiw input
  final String? Function(String?)? validator;

  // type mte3 keyboard: email, phone, text...
  final TextInputType? keyboardType;

  // true ken input password w text yetsattar
  final bool obscureText;

  // nombre mte3 lines
  final int maxLines;

  // icon optionnel fi lowel input
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // text controller
      controller: controller,

      // validation function
      validator: validator,

      // keyboard type
      keyboardType: keyboardType,

      // hide text ken password
      obscureText: obscureText,

      // max lines mte3 input
      maxLines: maxLines,

      // decoration mte3 input
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}
