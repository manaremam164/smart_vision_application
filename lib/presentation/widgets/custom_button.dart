import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/enums/social_provider.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final ButtonType buttonType;
  final SocialProvider? socialProvider;
  final Color? backgroundColor;
  final Color? textColor;
  final Color loadingColor;
  final Color iconColor;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.buttonType = ButtonType.primary,
    this.socialProvider,
    this.backgroundColor,
    this.textColor,
    this.loadingColor = Colors.white,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: _buildButtonStyle(context),
      onPressed: isLoading ? null : onPressed,
      child: _buildButtonContent(context),
    );
  }

  ButtonStyle _buildButtonStyle(BuildContext context) {
    final colors = _getButtonColors(context);
    
    return ElevatedButton.styleFrom(
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      elevation: 0,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        // side: _getBorderSide(colors),
      ),
      textStyle: AppTextStyles.buttonText.copyWith(color: colors.text),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    final colors = _getButtonColors(context);
    
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loadingColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTextStyles.buttonText.copyWith(
              color: colors.text ?? Colors.white,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null || socialProvider != null) ...[
          _getButtonIcon(colors),
          const SizedBox(width: 12),
        ],
        Text(
          text,
          style: AppTextStyles.buttonText.copyWith(
            color: colors.text ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _getButtonIcon(_ButtonColors colors) {
    final iconColor = this.iconColor;
    
    if (socialProvider != null) {
      return Icon(
        _getSocialIcon(socialProvider!),
        size: 24,
        color: iconColor,
      );
    }
    return Icon(
      icon,
      size: 24,
      color: iconColor,
    );
  }
  _ButtonColors _getButtonColors(BuildContext context) {
    if (backgroundColor != null || textColor != null) {
      return _ButtonColors(
        background: backgroundColor,
        foreground: textColor,
        text: textColor,
      );
    }

    switch (buttonType) {
      case ButtonType.primary:
        return _ButtonColors(
          background: AppColors.primary,
          foreground: Colors.white,
          text: AppColors.buttonPrimaryTextColor,
        );
      case ButtonType.secondary:
        return _ButtonColors(
          background: Colors.white,
          foreground: AppColors.primary,
          text: AppColors.buttonSecondaryTextColor,
        );
      case ButtonType.social:
        return _ButtonColors(
          background: _getSocialColor(socialProvider),
          foreground: _getSocialTextColor(socialProvider),
          text: _getSocialTextColor(socialProvider),
        );
      case ButtonType.danger:
        return _ButtonColors(
          background: AppColors.error,
          foreground: Colors.white,
          text: Colors.white,
        );  
    }
  }

  // BorderSide _getBorderSide(_ButtonColors colors) {
  //   return buttonType == ButtonType.secondary
  //       ? const BorderSide(color: AppColors.primary)
  //       : BorderSide(color: colors.background?.withOpacity(0.3) ?? Colors.transparent);
  // }

  Color _getSocialColor(SocialProvider? provider) {
    switch (provider) {
      case SocialProvider.google:
        return const Color(0xFFE34033);
      case SocialProvider.facebook:
        return const Color(0xFF0477F0);
      case SocialProvider.guest:
        return Colors.white;
      default:
        return AppColors.primary;
    }
  }

  Color _getSocialTextColor(SocialProvider? provider) {
    return provider == SocialProvider.guest ? Colors.black : Colors.white;
  }

  IconData _getSocialIcon(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.google:
        return Icons.g_mobiledata;
      case SocialProvider.facebook:
        return Icons.facebook_outlined;
      case SocialProvider.guest:
        return Icons.person_outlined;
      }
  }
}

class _ButtonColors {
  final Color? background;
  final Color? foreground;
  final Color? text;

  _ButtonColors({
    required this.background,
    required this.foreground,
    required this.text,
  });
}

enum ButtonType { primary, secondary, social, danger }