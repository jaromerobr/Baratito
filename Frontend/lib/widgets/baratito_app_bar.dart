/// Shared app bar with the Baratito green gradient (matches the Home header),
/// white title and icons. Use across the logged-in app for a consistent look.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// The green gradient used by the Home header and every Baratito app bar.
const LinearGradient kBaratitoHeaderGradient = LinearGradient(
  colors: [AppColors.primary, AppColors.primaryLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class BaratitoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  const BaratitoAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      // Container (sin hijo) llena todo el AppBar; un DecoratedBox colapsaría
      // a tamaño 0 y no se vería el verde.
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: kBaratitoHeaderGradient),
      ),
    );
  }
}
