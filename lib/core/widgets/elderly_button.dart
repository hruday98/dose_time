import 'package:flutter/material.dart';

enum ElderlyButtonVariant { primary, secondary, tertiary, danger }

/// ElderlyButton is an accessible button widget designed for elderly users
class ElderlyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ElderlyButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;

  const ElderlyButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.variant = ElderlyButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.icon,
  }) : super(key: key);

  Color _getBackgroundColor() {
    switch (variant) {
      case ElderlyButtonVariant.primary:
        return Colors.blue;
      case ElderlyButtonVariant.secondary:
        return Colors.grey[300]!;
      case ElderlyButtonVariant.tertiary:
        return Colors.transparent;
      case ElderlyButtonVariant.danger:
        return Colors.red;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ElderlyButtonVariant.primary:
        return Colors.white;
      case ElderlyButtonVariant.secondary:
        return Colors.black87;
      case ElderlyButtonVariant.tertiary:
        return Colors.blue;
      case ElderlyButtonVariant.danger:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getTextColor(),
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: variant == ElderlyButtonVariant.tertiary
                ? BorderSide(color: _getTextColor())
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
