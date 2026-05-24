import 'dart:math' as math;

/// Truncates [value] to [decimalPlaces] fractional digits without rounding up.
double truncatePoints(double value, [int decimalPlaces = 2]) {
  if (value.isNaN || value.isInfinite) return 0;
  final factor = math.pow(10, decimalPlaces).toDouble();
  if (value >= 0) {
    return (value * factor).truncateToDouble() / factor;
  }
  return -((-value * factor).truncateToDouble() / factor);
}

/// Formats CPD point values to at most 2 decimal places, truncated not rounded.
///
/// Examples: 0.75 → "0.75", 2.666… → "2.66", 1.5 → "1.5", 60.0 → "60"
String formatPoints(double value) {
  if (value.isNaN || value.isInfinite) return '0';

  final truncated = truncatePoints(value, 2);
  if (truncated == truncated.roundToDouble()) {
    return truncated.toInt().toString();
  }

  var text = truncated.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}
