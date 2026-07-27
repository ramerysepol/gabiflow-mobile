import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Campo de texto premium com label animado, estados de erro e helper.
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.validator,
    this.autocorrect = true,
    this.readOnly = false,
    this.hintText,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final bool autocorrect;
  final bool readOnly;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: errorText != null ? null : 56,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autocorrect: autocorrect,
        readOnly: readOnly,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffix,
          errorText: errorText,
          helperText: helperText,
          // Sobrescreve apenas a cor do helper/error para usar tokens
          helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.neutral600Dark
                : AppColors.neutral600Light,
          ),
          errorStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.dangerDark
                : AppColors.dangerLight,
          ),
        ),
      ),
    );
  }
}
