import 'package:intl/intl.dart';

class MedicalFormatters {
  MedicalFormatters._();

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _dateFormat.format(dateTime);
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _timeFormat.format(dateTime);
  }

  static String formatRemainingIschemicTime(Duration remaining) {
    if (remaining.isNegative) {
      return 'EXPIRED';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDistance(double kilometers) {
    if (kilometers < 1.0) {
      return '${(kilometers * 1000).toInt()} m';
    }
    return '${kilometers.toStringAsFixed(1)} km';
  }

  static String formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
