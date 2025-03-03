import 'package:intl/intl.dart';

/// A utility class that provides date formatting functions
class DateFormatter {
  /// Format a date to a standard display format: Jan 1, 2023
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format a date to show the time: 12:30 PM
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format a date to show date and time: Jan 1, 2023 - 12:30 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  /// Format a date to show relative time: 2 hours ago, Yesterday, etc.
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Format a duration to a readable string: 2h 30m
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format date for API requests: yyyy-MM-dd
  static String formatForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date in compact form: 01/01/2023
  static String formatCompact(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Format date for filenames (without spaces or special chars): 20230101_123045
  static String formatForFilename(DateTime date) {
    return DateFormat('yyyyMMdd_HHmmss').format(date);
  }

  /// Return date range as string: Jan 1 - Jan 5, 2023
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      // Same month and year: Jan 1-5, 2023
      return '${DateFormat('MMM d').format(start)}-${DateFormat('d, yyyy').format(end)}';
    } else if (start.year == end.year) {
      // Same year: Jan 1 - Feb 5, 2023
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    } else {
      // Different years: Jan 1, 2022 - Jan 5, 2023
      return '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    }
  }

  /// Get short weekday name: Mon, Tue, etc.
  static String getShortWeekday(DateTime date) {
    return DateFormat('E').format(date);
  }

  /// Get short month name: Jan, Feb, etc.
  static String getShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  /// Returns true if the date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Returns true if the date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// Returns true if the date is within last 7 days
  static bool isWithinLastWeek(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    return difference.inDays < 7;
  }
}