import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static final DateFormat _dayMonthYearFormat = DateFormat("d 'de' MMMM 'de' yyyy", 'es');
  static final DateFormat _dayMonthFormat = DateFormat("d 'de' MMMM", 'es');
  static final DateFormat _monthYearFormat = DateFormat("MMMM yyyy", 'es');
  static final DateFormat _dayOfWeekShort = DateFormat("E", 'es');
  static final DateFormat _dayAndMonthShort = DateFormat("d MMM", 'es');

  static String formatFullDate(DateTime date) {
    return _dayMonthYearFormat.format(date);
  }

  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    final formatted = _monthYearFormat.format(date);
    if (formatted.isEmpty) return '';
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String formatTime(dynamic time) {
    int hour = 0;
    int minute = 0;
    if (time is TimeOfDay) {
      hour = time.hour;
      minute = time.minute;
    } else if (time is DateTime) {
      hour = time.hour;
      minute = time.minute;
    } else if (time != null) {
      final str = time.toString();
      final partes = str.split(':');
      if (partes.length >= 2) {
        hour = int.tryParse(partes[0].trim()) ?? 0;
        final minutePart = partes[1].trim().split(' ')[0];
        minute = int.tryParse(minutePart) ?? 0;
      } else {
        return str;
      }
    } else {
      return '';
    }

    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $period';
  }

  static String formatTimeOfDayString(DateTime dateTime) {
    return formatTime(dateTime);
  }

  static String getDayNameShort(DateTime date) {
    final name = _dayOfWeekShort.format(date);
    return name.replaceAll('.', '').capitalize();
  }

  static String formatShortDayMonth(DateTime date) {
    return _dayAndMonthShort.format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static DateTime startOfWeek(DateTime date, {int firstDayOfWeek = DateTime.monday}) {
    final diff = date.weekday - firstDayOfWeek;
    final normalizedDiff = diff < 0 ? diff + 7 : diff;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: normalizedDiff));
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
