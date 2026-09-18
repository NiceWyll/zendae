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
    if (time is TimeOfDay) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return time.toString();
  }

  static String formatTimeOfDayString(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
