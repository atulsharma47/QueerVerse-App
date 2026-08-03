import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;

  final String label;

  final IconData icon;

  final bool isPassword;

  final bool enabled;

  final TextInputType keyboardType;

  final TextInputAction textInputAction;

  final Widget? suffix;

  final String? Function(String?)? validator;

  final void Function(String)? onChanged;

  final void Function(String)? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final FocusNode _focusNode = FocusNode();

  bool _obscure = true;

  bool get _focused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .06),
            Colors.white.withValues(alpha: .03),
          ],
        ),

        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.border,
          width: _focused ? 1.6 : 1,
        ),

        boxShadow: [
          if (_focused)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .22),
              blurRadius: 25,
              spreadRadius: 1,
            ),
        ],
      ),

      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,

        enabled: widget.enabled,

        validator: widget.validator,

        keyboardType: widget.keyboardType,

        textInputAction: widget.textInputAction,

        obscureText: widget.isPassword ? _obscure : false,

        onChanged: widget.onChanged,

        onFieldSubmitted: widget.onSubmitted,

        cursorColor: AppColors.primary,

        style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 15),

        decoration: InputDecoration(
          border: InputBorder.none,

          // Keep the label sitting inside the field as a static
          // placeholder instead of floating up — the outer border
          // is custom-painted (InputBorder.none) so there's no gap
          // reserved for a floated label, which caused the border
          // line to cut straight through the text.
          floatingLabelBehavior: FloatingLabelBehavior.never,

          hintText: widget.label,

          hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),

          prefixIcon: Icon(
            widget.icon,
            color: _focused ? AppColors.primary : AppColors.textSecondary,
          ),

          suffixIcon: widget.isPassword
              ? IconButton(
                  splashRadius: 20,
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      key: ValueKey(_obscure),
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : widget.suffix,
        ),
      ),
    );
  }
}
