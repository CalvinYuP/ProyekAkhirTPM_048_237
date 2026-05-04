// lib/core/utils/time_converter.dart
class TimeConverter {
  // Offset jam dari UTC
  static const Map<String, int> timeZones = {
    'WIB': 7,    // Western Indonesia Time
    'WITA': 8,   // Central Indonesia Time
    'WIT': 9,    // Eastern Indonesia Time
    'Kuala Lumpur': 8, // MYT (Malaysia Time)
    'Singapore': 8,    // SGT (Singapore Time)
    'London': 1, // BST (British Summer Time)
    'Dubai': 4,  // GST (Gulf Standard Time)
    'Tokyo': 9,  // JST (Japan Standard Time)
  };

  static const Map<String, String> timeZoneLabels = {
    'WIB': 'WIB (Jakarta)',
    'WITA': 'WITA (Makassar)',
    'WIT': 'WIT (Jayapura)',
    'Kuala Lumpur': 'Kuala Lumpur (MYT)',
    'Singapore': 'Singapore (SGT)',
    'London': 'London (BST)',
    'Dubai': 'Dubai (GST)',
    'Tokyo': 'Tokyo (JST)',
  };

  // Konversi jam (format "HH:mm" dari WIB) ke timezone target
  static String convertTime(String timeWIB, String targetTimeZone) {
    try {
      final parts = timeWIB.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final wibOffset = timeZones['WIB']!;
      final targetOffset = timeZones[targetTimeZone] ?? wibOffset;
      final diff = targetOffset - wibOffset;

      hour += diff;
      
      // Handle overflow/underflow
      if (hour >= 24) hour -= 24;
      if (hour < 0) hour += 24;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeWIB;
    }
  }

  // Format jam buka - tutup
  static String formatTimeRange(String openWIB, String closeWIB, String timeZone) {
    final open = convertTime(openWIB, timeZone);
    final close = convertTime(closeWIB, timeZone);
    return '$open - $close';
  }

  static List<String> getAvailableTimeZones() => timeZones.keys.toList();
}