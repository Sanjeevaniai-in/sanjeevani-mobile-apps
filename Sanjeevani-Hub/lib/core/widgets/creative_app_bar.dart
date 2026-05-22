import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class CreativeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const CreativeAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8, // Reduced top padding
        left: 24,
        right: 24,
        bottom: 8, // Reduced bottom padding
      ),
      color: Colors.transparent, // Transparent for full screen effect
      child: Row(
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Center(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
          if (actions != null) ...actions!,
          if (actions == null && leading != null)
            const SizedBox(width: 48), // Balance leading
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
