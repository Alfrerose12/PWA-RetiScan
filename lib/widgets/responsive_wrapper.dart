import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        EdgeInsets responsivePadding;
        if (padding != null) {
          responsivePadding = padding!;
        } else {
          if (screenWidth > 1200) {
            responsivePadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
          } else if (screenWidth > 800) {
            responsivePadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
          } else {
            responsivePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
          }
        }

        if (screenWidth > maxWidth) {
          return Center(
            child: Container(
              width: maxWidth,
              padding: responsivePadding,
              child: child,
            ),
          );
        }

        return Padding(
          padding: responsivePadding,
          child: child,
        );
      },
    );
  }
}

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktop) return 3;
    if (width >= tablet) return 2;
    return 1;
  }
}
