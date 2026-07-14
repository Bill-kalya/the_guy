import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1280;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}

/// Responsive layout widget that switches between mobile, tablet, and desktop layouts
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return desktop;
        }
        if (tablet != null && constraints.maxWidth >= Breakpoints.mobile) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Adaptive padding that changes based on screen size
class AdaptivePadding extends StatelessWidget {
  final Widget child;

  const AdaptivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (Breakpoints.isDesktop(width)) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

/// Adaptive grid that changes column count based on screen size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (Breakpoints.isDesktop(width)) {
          crossAxisCount = 4;
          childAspectRatio = 1.2;
        } else if (Breakpoints.isTablet(width)) {
          crossAxisCount = 3;
          childAspectRatio = 1.1;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.0;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive text that scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    super.key,
    this.mobileSize = 16,
    this.tabletSize,
    this.desktopSize,
    this.fontWeight,
    this.color,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double size;

        if (Breakpoints.isDesktop(width)) {
          size = desktopSize ?? mobileSize * 1.4;
        } else if (Breakpoints.isTablet(width)) {
          size = tabletSize ?? mobileSize * 1.2;
        } else {
          size = mobileSize;
        }

        return Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: fontWeight,
            color: color,
          ),
          textAlign: textAlign,
        );
      },
    );
  }
}