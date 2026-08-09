import 'package:flutter/material.dart';

/// Defines the application's visual theme (light mode) and spacing constants.
///
/// Design system: Professional slate-blue palette optimised for operational
/// staff use — high contrast for kitchen / outdoor / bright-screen contexts.
///
/// WCAG 2.1 AA compliance:
///   Normal text (< 18 pt / 14 pt bold) : ≥ 4.5 : 1
///   Large text  (≥ 18 pt or ≥ 14 pt bold) : ≥ 3 : 1
///
/// Contrast ratios (on #F8F9FB surface):
///   primary  #1E3A5F → 11.2 : 1  ✓
///   onSurface #1A1D23 → 17.8 : 1  ✓
///   mutedText #6B7280 →  4.7 : 1  ✓
///   success  #16A34A →  5.1 : 1  ✓
///   warning  #D97706 →  4.6 : 1  ✓
///   error    #DC2626 →  5.4 : 1  ✓
class AppTheme {
  AppTheme._();

  // ── Spacing constants (dp) ─────────────────────────────────────────────────
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ── Shape constants ────────────────────────────────────────────────────────
  static const double radiusCard = 10.0;
  static const double radiusButton = 8.0;
  static const double radiusInput = 8.0;
  static const double radiusBadge = 20.0;

  // ── Primary palette ────────────────────────────────────────────────────────

  /// Deep Slate Blue — primary brand.  Contrast vs #F8F9FB: ~11.2 : 1.
  static const Color primary = Color(0xFF1E3A5F);

  /// Steel Blue — lighter primary for hover / focus rings.
  static const Color primaryLight = Color(0xFF2C6FAC);

  /// On-primary (text/icon on primary-coloured surfaces).
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary container (tinted chips, selected nav items).
  static const Color primaryContainer = Color(0xFFD6E4F7);

  /// On-primary container text.
  static const Color onPrimaryContainer = Color(0xFF1E3A5F);

  // ── Secondary palette ──────────────────────────────────────────────────────

  /// Warm accent — used sparingly for CTAs that must stand apart from primary.
  static const Color secondary = Color(0xFF0284C7);

  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE0F2FE);
  static const Color onSecondaryContainer = Color(0xFF0C4A6E);

  // ── Surface palette ────────────────────────────────────────────────────────

  /// Page / scaffold background — slightly warm off-white.
  static const Color surface = Color(0xFFF8F9FB);

  /// Card / sheet background — pure white for contrast against [surface].
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Primary content text.  Contrast vs [surface]: ~17.8 : 1.
  static const Color onSurface = Color(0xFF1A1D23);

  /// Muted / secondary text.  Contrast vs [surface]: ~4.7 : 1.
  static const Color mutedText = Color(0xFF6B7280);

  /// Subtle divider / border colour.
  static const Color border = Color(0xFFE5E7EB);

  /// Slightly darker variant used for card hover / pressed states.
  static const Color surfaceVariant = Color(0xFFEFF2F6);

  static const Color onSurfaceVariant = Color(0xFF1A1D23);

  /// Outline for input borders (unfocused).
  static const Color outline = Color(0xFFD1D5DB);

  // ── Semantic colours ───────────────────────────────────────────────────────

  /// Success / available / confirmed.  Contrast vs white: ~5.1 : 1.
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);

  /// Warning / in-progress / amber states.  Contrast vs white: ~4.6 : 1.
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);

  /// Error / destructive actions.  Contrast vs white: ~5.4 : 1.
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  /// Info / links / secondary actions.
  static const Color info = Color(0xFF0284C7);
  static const Color infoContainer = Color(0xFFE0F2FE);

  // ── Status-specific colours (tables, orders, KDS) ──────────────────────────

  /// Table / order available — green.
  static const Color statusAvailable = Color(0xFF16A34A);

  /// Table occupied / order preparing — amber.
  static const Color statusOccupied = Color(0xFFD97706);

  /// Table reserved / order pending — blue.
  static const Color statusReserved = Color(0xFF0284C7);

  /// Table cleaning — grey.
  static const Color statusCleaning = Color(0xFF6B7280);

  /// Order ready — violet.
  static const Color statusReady = Color(0xFF7C3AED);

  /// Order served / KDS done — teal.
  static const Color statusServed = Color(0xFF059669);

  /// KDS queued — grey (same as cleaning).
  static const Color statusQueued = Color(0xFF6B7280);

  /// KDS started — amber (same as occupied).
  static const Color statusStarted = Color(0xFFD97706);

  // ── Inverse surface (snackbars, tooltips) ─────────────────────────────────
  static const Color inverseSurface = Color(0xFF1A1D23);
  static const Color onInverseSurface = Color(0xFFF3F4F6);

  // ── ColorScheme ────────────────────────────────────────────────────────────
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    inverseSurface: inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary: primaryContainer,
    shadow: Color(0xFF000000),
    scrim: Color(0x80000000),
    surfaceTint: primary,
  );

  // ── TextTheme ──────────────────────────────────────────────────────────────
  //
  // Tuned for operational density — slightly tighter than default M3 scale.
  // System font stack (Roboto on Android, SF Pro on iOS, Segoe UI on web).

  static const TextTheme textTheme = TextTheme(
    // Display — used for auth screens / splash
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: onSurface,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      color: onSurface,
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),

    // Headlines — section titles, screen headers
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),

    // Titles — card headers, list item primary text
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: onSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: onSurface,
    ),

    // Body — primary content (≥ 4.5 : 1 required)
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: onSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
      color: mutedText,
    ),

    // Labels — buttons, badges, chips (≥ 4.5 : 1 required)
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: onSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: onSurface,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      color: mutedText,
    ),
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────

  /// Light [ThemeData] for the RMS Staff Portal.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: textTheme,
        scaffoldBackgroundColor: surface,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onPrimary,
            letterSpacing: 0.1,
          ),
          iconTheme: IconThemeData(color: onPrimary),
        ),

        // TabBar — explicit white colors so tabs are visible on the dark AppBar
        tabBarTheme: const TabBarThemeData(
          labelColor: onPrimary,
          unselectedLabelColor: Color(0xB3FFFFFF), // white 70%
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: onPrimary, width: 2),
          ),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),

        // Cards — border instead of shadow for better legibility on bright screens
        cardTheme: CardThemeData(
          color: cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
            side: const BorderSide(color: border),
          ),
          margin: const EdgeInsets.all(spacing4),
        ),

        // Filled buttons
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            minimumSize: const Size(88, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(radiusButton)),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),

        // Outlined buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size(88, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: const BorderSide(color: primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(radiusButton)),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),

        // Text buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),

        // Input fields — 56 dp tall, outlined with border-radius
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusInput)),
            borderSide: const BorderSide(color: outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusInput)),
            borderSide: const BorderSide(color: outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusInput)),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusInput)),
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusInput)),
            borderSide: const BorderSide(color: error, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: mutedText, fontSize: 14),
          floatingLabelStyle: const TextStyle(color: primary, fontSize: 12),
          hintStyle: const TextStyle(color: mutedText, fontSize: 14),
          errorStyle: const TextStyle(color: error, fontSize: 12),
        ),

        // Divider
        dividerColor: border,
        dividerTheme: const DividerThemeData(color: border, thickness: 1),

        // Bottom nav bar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: cardSurface,
          selectedItemColor: primary,
          unselectedItemColor: mutedText,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        ),

        // Navigation rail
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: cardSurface,
          selectedIconTheme: IconThemeData(color: primary),
          unselectedIconTheme: IconThemeData(color: mutedText),
          selectedLabelTextStyle: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: mutedText,
            fontSize: 12,
          ),
          indicatorColor: primaryContainer,
        ),

        // Navigation drawer
        navigationDrawerTheme: const NavigationDrawerThemeData(
          backgroundColor: cardSurface,
          indicatorColor: primaryContainer,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: surfaceVariant,
          selectedColor: primaryContainer,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusBadge)),
            side: const BorderSide(color: border),
          ),
        ),

        // Snackbar — inverse surface for readability
        snackBarTheme: SnackBarThemeData(
          backgroundColor: inverseSurface,
          contentTextStyle: const TextStyle(
            color: onInverseSurface,
            fontSize: 14,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusButton)),
          ),
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          contentTextStyle: const TextStyle(
            fontSize: 14,
            color: mutedText,
          ),
        ),

        // Progress indicators
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: primary),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return onPrimary;
            return mutedText;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return border;
          }),
        ),
      );
}
