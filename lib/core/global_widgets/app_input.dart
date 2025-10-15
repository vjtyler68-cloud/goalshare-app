import 'package:flutter/material.dart';



class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.hint,
    required this.controller,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.obscureText = false,
    this.validator,
    this.textType,
    this.onClick,
    this.onChanged,
    this.maxLine = 1,
    this.isValidatorNeed = true,
    this.circle = 10,
    this.hintColor = Colors.grey,
    this.fillColor = Colors.white,
    this.onSubmit,
  });
  final String hint;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? textType;
  final VoidCallback? onClick;
  final Function(String)? onChanged;
  final Function(String)? onSubmit;

  final int maxLine;
  final bool isValidatorNeed;
  final double circle;
  final Color hintColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        onFieldSubmitted: onSubmit,
        onTap: onClick,
        onChanged: onChanged,
        maxLines: maxLine,
        keyboardType: textType,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
        ),
        readOnly: readOnly,
        obscureText: obscureText,
        controller: controller,
        validator: (v) {
          if (isValidatorNeed) {
            if (v!.isEmpty) {
              return "Must be required.";
            }
            return null;
          }
          return null;
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.only(left: 10),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(circle),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(circle),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(circle),
            borderSide: BorderSide.none,
          ),
          focusColor: Colors.grey.shade300,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(circle),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
