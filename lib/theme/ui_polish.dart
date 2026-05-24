import 'package:flutter/material.dart';

/// Master switch for the UI polish pass.
/// Set to false to instantly revert all polish changes to the pre-polish UI.
const bool kUsePolishedUI = true;

/// Category accent colours — used for left border strips on category cards.
/// Index 0 = Category 1, Index 9 = Category 10.
const List<Color> kCategoryAccentColors = [
  Color(0xFF0082C8), // 1 Educational Events — CHIA Blue
  Color(0xFF7C3AED), // 2 Structured Education Courses — Purple
  Color(0xFF059669), // 3 Reading — Green
  Color(0xFFF59E0B), // 4 Presentation — Amber
  Color(0xFFDC2626), // 5 Publication — Red
  Color(0xFF0891B2), // 6 Professional Service — Cyan
  Color(0xFF6D28D9), // 7 Reviewing Publications — Violet
  Color(0xFF065F46), // 8 Mentoring — Dark Green
  Color(0xFFD97706), // 9 Discussion Groups — Dark Amber
  Color(0xFF1D4ED8), // 10 Workplace Activities — Dark Blue
];

/// Polished shadow — replaces flat cards with subtle depth
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

/// Original shadow — used when kUsePolishedUI = false (revert mode)
const List<BoxShadow> kOriginalShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
];

Color categoryAccentForId(int categoryId) {
  return kCategoryAccentColors[(categoryId - 1).clamp(0, 9)];
}

List<BoxShadow> cardShadowForPolish(List<BoxShadow> fallback) {
  return kUsePolishedUI ? kPolishedShadow : fallback;
}

/// ISO date (yyyy-MM-dd) → display form e.g. "23 May 2029"
String formatDateForDisplay(String iso) {
  try {
    final date = DateTime.parse(iso);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return iso;
  }
}

/// Section heading with accent bar — polished version
Widget polishedSectionHeading(String title) {
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1321),
        ),
      ),
    ],
  );
}

/// Original section heading — used when reverting
Widget originalSectionHeading(String title, TextStyle? style) {
  return Text(
    title,
    style: style ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1321),
        ),
  );
}

/// Use wherever section headings appear (pass [style] when using Theme text styles).
Widget sectionHeading(String title, {TextStyle? style}) {
  return kUsePolishedUI
      ? polishedSectionHeading(title)
      : originalSectionHeading(title, style);
}

/// Custom fade+slide page transition for polished UI.
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

PageTransitionsTheme? polishedPageTransitionsTheme() {
  if (!kUsePolishedUI) return null;
  return const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
    },
  );
}

/// Staggered fade-in for list items (no extra packages).
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
    if (kUsePolishedUI) {
      Future<void>.delayed(
        Duration(milliseconds: 40 * widget.index.clamp(0, 12)),
        () {
          if (mounted) _controller.forward();
        },
      );
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kUsePolishedUI) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
