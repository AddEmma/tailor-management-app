import 'package:flutter/material.dart';

/// Breakpoint constants for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  /// Check if the screen is mobile-sized
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  /// Check if the screen is tablet-sized
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }

  /// Check if the screen is desktop-sized
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Get the current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobile) return DeviceType.mobile;
    if (width < desktop) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// A widget that builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// A helper class for responsive values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({required this.mobile, this.tablet, this.desktop});

  /// Get the appropriate value for the current screen size
  T get(BuildContext context) {
    final deviceType = Breakpoints.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Extension for easy responsive padding
extension ResponsiveSpacing on BuildContext {
  /// Get responsive horizontal padding
  EdgeInsets get responsivePadding {
    final deviceType = Breakpoints.getDeviceType(this);
    switch (deviceType) {
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
    }
  }

  /// Get responsive grid crossAxisCount for items
  int get responsiveGridCount {
    final deviceType = Breakpoints.getDeviceType(this);
    switch (deviceType) {
      case DeviceType.desktop:
        return 3;
      case DeviceType.tablet:
        return 2;
      case DeviceType.mobile:
        return 1;
    }
  }

  /// Get max content width for centered layouts
  double get maxContentWidth {
    final deviceType = Breakpoints.getDeviceType(this);
    switch (deviceType) {
      case DeviceType.desktop:
        return 1200;
      case DeviceType.tablet:
        return 800;
      case DeviceType.mobile:
        return double.infinity;
    }
  }
}

/// A wrapper widget that centers content with a max width
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.maxContentWidth,
        ),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// A responsive grid that automatically adjusts column count
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        if (constraints.maxWidth >= Breakpoints.desktop) {
          columns = desktopColumns ?? 3;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          columns = tabletColumns ?? 2;
        } else {
          columns = mobileColumns ?? 1;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            final itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}

/// A widget that adapts between Row and Column based on screen width
class AdaptiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const AdaptiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = !Breakpoints.isMobile(context);

    final spacedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spacedChildren.add(
          SizedBox(width: isWide ? spacing : 0, height: isWide ? 0 : spacing),
        );
      }
      spacedChildren.add(isWide ? Expanded(child: children[i]) : children[i]);
    }

    if (isWide) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: spacedChildren,
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: spacedChildren,
      );
    }
  }
}
