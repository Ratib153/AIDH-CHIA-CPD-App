/// Formats an ISO 8601 date string as a human-readable date.
/// Example: `2026-05-24` → `24 May 2026`
String formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}
