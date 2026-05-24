import 'package:flutter/material.dart';

/// Category accent colours for left border strips. Index 0 = Category 1.
const List<Color> kCategoryAccentColors = [
  Color(0xFF0082C8),
  Color(0xFF7C3AED),
  Color(0xFF059669),
  Color(0xFFF59E0B),
  Color(0xFFDC2626),
  Color(0xFF0891B2),
  Color(0xFF6D28D9),
  Color(0xFF065F46),
  Color(0xFFD97706),
  Color(0xFF1D4ED8),
];

const List<BoxShadow> kPolishedShadow = [
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 4,
    offset: Offset(0, 1),
    spreadRadius: 0,
  ),
];

Color categoryAccentForId(int categoryId) {
  return kCategoryAccentColors[(categoryId - 1).clamp(0, 9)];
}

Widget sectionHeading(String title, {TextStyle? style}) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF0082C8),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: style ??
            const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1321),
            ),
      ),
    ],
  );
}

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

const PageTransitionsTheme kPolishedPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
  },
);

/// Staggered fade-in for list items.
class PolishedListFadeIn extends StatefulWidget {
  const PolishedListFadeIn({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<PolishedListFadeIn> createState() => _PolishedListFadeInState();
}

class _PolishedListFadeInState extends State<PolishedListFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(
      Duration(milliseconds: 40 * widget.index.clamp(0, 12)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
