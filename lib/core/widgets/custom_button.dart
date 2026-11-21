import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

/// Reusable button widget matching the Medilab ProKit medical style.
///
/// Provides filled (primary) and outlined variants with consistent
/// teal/green theming and rounded corners.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outlined;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final double fontSize;
  final FontWeight? fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
    this.isLoading = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
    this.height = 48,
    this.fontSize = 15,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primaryColor;
    final buttonTextColor = textColor ?? Colors.white;

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(buttonTextColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: buttonTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  color: buttonTextColor,
                ),
              ),
            ],
          );

    final button = outlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              side: BorderSide(color: buttonColor, width: 1.5),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              fixedSize: Size(width ?? double.infinity, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: content,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              fixedSize: Size(width ?? double.infinity, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: content,
          );

    return button;
  }
}
