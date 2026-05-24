/// Formats CPD point values without rounding fractional amounts.
///
/// Examples: 0.75 → "0.75", 1.5 → "1.5", 2.0 → "2", 60.0 → "60"
String formatPoints(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  var text = value.toString();
  if (!text.contains('e') && !text.contains('E') && text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  text = value.toStringAsFixed(10);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}
