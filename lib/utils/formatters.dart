/// Display helpers shared by the redesigned screens (no extra packages needed).
class Fmt {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// 2050 → "2,050"; -100 → "-100"
  static String number(num? value) {
    final n = (value ?? 0).round();
    final negative = n < 0;
    final digits = n.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return negative ? '-$buf' : buf.toString();
  }

  /// "2,050 pts"
  static String pts(num? value) => '${number(value)} pts';

  /// Signed points for activity rows: "+2,000" / "-50"
  static String signedPts(num? value) {
    final n = (value ?? 0).round();
    return n > 0 ? '+${number(n)}' : number(n);
  }

  /// Parses API timestamps into local time. Returns null when missing or invalid.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// "2 Oct 2026"
  static String date(DateTime? d) => d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// "Sat 14 Jun"
  static String dayDate(DateTime? d) => d == null ? 'Date TBA' : '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// "7:30 am"
  static String time(DateTime? d) {
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }

  /// "DD/MM/YYYY" for the date of birth field
  static String dmy(DateTime? d) =>
      d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// "YYYY-MM-DD" for the API
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// "3 hours ago" / "Yesterday" / "2 Oct 2026"
  static String relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return date(d);
  }

  /// "Good morning" / "Good afternoon" / "Good evening" for the device's local time
  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static int toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
