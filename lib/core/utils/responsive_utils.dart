import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform and screen size detection utilities
class ResponsiveUtils {
  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Check if running on mobile (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check screen width for responsive design
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  /// Check if should use desktop layout (desktop platform + wide screen)
  static bool useDesktopLayout(BuildContext context) {
    return isDesktop && isWideScreen(context);
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (width > 800) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  /// Get responsive content max width
  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 1200;
    if (width > 1000) return 900;
    return double.infinity;
  }
}

/// Screen size breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wide = 1600;
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On desktop platforms with wide screen, use desktop layout
        if (ResponsiveUtils.useDesktopLayout(context)) {
          return desktop;
        }

        // For tablets or wide mobile screens
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return tablet ?? desktop;
        }

        // Mobile layout
        return mobile;
      },
    );
  }
}

/// Adaptive layout that switches between side and bottom navigation
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final List<AdaptiveDestination> destinations;
  final List<Widget> body;
  final ValueChanged<int> onDestinationSelected;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.body,
    required this.onDestinationSelected,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildMobileLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: body[currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail for Windows
          _buildSideNavigation(context, isDark),
          // Main content area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: body[currentIndex],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildSideNavigation(BuildContext context, bool isDark) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF18181B) // darkSurface
            : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? const Color(0xFF3F3F46) // darkBorder
                : const Color(0xFFE4E4E7), // lightBorder
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Conto',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  final isSelected = currentIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onDestinationSelected(index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C3AED).withAlpha(26)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withAlpha(51),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? dest.selectedIcon : dest.icon,
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : (isDark
                                          ? const Color(0xFFA1A1AA)
                                          : Colors.grey[600]),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                dest.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : (isDark
                                            ? const Color(0xFFA1A1AA)
                                            : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom section with version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF71717A) // Zinc-500
                      : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: destinations.asMap().entries.map((entry) {
              final index = entry.key;
              final dest = entry.value;
              final isSelected = currentIndex == index;

              return GestureDetector(
                onTap: () => onDestinationSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withAlpha(26)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? dest.selectedIcon : dest.icon,
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : (isDark
                                  ? const Color(0xFFA1A1AA)
                                  : Colors.grey[600]),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dest.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : (isDark
                                    ? const Color(0xFFA1A1AA)
                                    : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Destination item for adaptive navigation
class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
