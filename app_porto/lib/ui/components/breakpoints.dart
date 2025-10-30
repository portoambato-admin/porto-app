// lib/ui/components/breakpoints.dart
import 'package:flutter/widgets.dart';

/// Breakpoints acordados:
/// - <600  : móvil (Drawer + modals fullscreen)
/// - 600–1024: tablet
/// - ≥1024 : desktop (NavigationRail + slide-over 420–520 px)
const double kMobileBp = 600.0;
const double kTabletBp = 1024.0;

extension ResponsiveX on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isMobile => screenWidth < kMobileBp;
  bool get isTablet => screenWidth >= kMobileBp && screenWidth < kTabletBp;
  bool get isDesktop => screenWidth >= kTabletBp;
}
