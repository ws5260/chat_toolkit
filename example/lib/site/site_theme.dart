import 'package:material_ui/material_ui.dart';

/// Colors of the demo site: near-neutral cool greys with one blue accent.
abstract final class SiteColors {
  static const blue = Color(0xFF3182F6);
  static const blueWeak = Color(0xFFE8F3FF);
  static const grey900 = Color(0xFF191F28);
  static const grey800 = Color(0xFF333D4B);
  static const grey700 = Color(0xFF4E5968);
  static const grey600 = Color(0xFF6B7684);
  static const grey500 = Color(0xFF8B95A1);
  static const grey400 = Color(0xFFB0B8C1);
  static const grey300 = Color(0xFFD1D6DB);
  static const grey200 = Color(0xFFE5E8EB);
  static const grey100 = Color(0xFFF2F4F6);
  static const grey50 = Color(0xFFF9FAFB);
  static const red = Color(0xFFF04452);

  /// Page background behind the white cards.
  static const background = grey100;
}

abstract final class SiteShadows {
  static const card = [
    BoxShadow(color: Color(0x0A0B1A33), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x1A0B1A33), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0F0B1A33), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

ThemeData buildSiteTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SiteColors.blue,
    primary: SiteColors.blue,
    surface: Colors.white,
    onSurface: SiteColors.grey900,
  );
  const textTheme = TextTheme(
    headlineMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.5),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.35),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.45),
    bodyLarge: TextStyle(fontSize: 15, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, height: 1.5),
    bodySmall: TextStyle(fontSize: 13, height: 1.5, color: SiteColors.grey600),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SiteColors.background,
    textTheme: textTheme.apply(
      bodyColor: SiteColors.grey900,
      displayColor: SiteColors.grey900,
    ),
    dividerColor: SiteColors.grey200,
    dividerTheme: const DividerThemeData(color: SiteColors.grey200, space: 1, thickness: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: SiteColors.grey900,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? SiteColors.blue : SiteColors.grey300),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: SiteColors.blue,
      inactiveTrackColor: SiteColors.grey200,
      thumbColor: Colors.white,
      overlayColor: Color(0x143182F6),
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SiteColors.grey900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// White rounded card on the grey page.
class SiteCard extends StatelessWidget {
  const SiteCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: SiteShadows.card,
        ),
        child: child,
      );
}

/// Grey, rounded secondary button.
class SiteButton extends StatelessWidget {
  const SiteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : SiteColors.grey800;
    return Material(
      color: primary ? SiteColors.blue : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: primary
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SiteColors.grey200),
                ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
          ]),
        ),
      ),
    );
  }
}
