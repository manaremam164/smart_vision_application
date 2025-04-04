import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
        color: AppColors.buttonPrimaryTextColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                cursorColor: AppColors.textPrimary,
                cursorHeight: 16,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Whats in your mind',
                  hintStyle: TextStyle(
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

