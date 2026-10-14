import '../network/api_constants.dart';
import '../../data/models/daily_agenda_model.dart';

class CalendarExportHelper {
  /// Generates a Google Calendar Web Intent URL for adding an activity
  static String buildGoogleCalendarUrl({
    required String title,
    required String description,
    required String dateStr, // YYYY-MM-DD
    required String timeStr, // HH:mm
    int durationMinutes = 30,
  }) {
    try {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      final start = DateTime.parse('${dateStr}T${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00');
      final end = start.add(Duration(minutes: durationMinutes));

      final startFormatted = _formatDateTimeToUtc(start);
      final endFormatted = _formatDateTimeToUtc(end);

      final encodedTitle = Uri.encodeComponent('Retiva: $title');
      final encodedDesc = Uri.encodeComponent('$description\n\n[Jadwal Perawatan Mandiri Retiva]');
      final encodedLocation = Uri.encodeComponent('Rumah / Faskes Terdekat');

      return 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$encodedTitle&dates=$startFormatted/$endFormatted&details=$encodedDesc&location=$encodedLocation';
    } catch (_) {
      return 'https://calendar.google.com/calendar';
    }
  }

  /// Builds a standard RFC 5545 iCalendar (.ics) string for today's agenda
  static String buildIcsString({
    required List<DailyAgendaItem> items,
    required String dateStr,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Retiva Healthcare//Daily Care Companion//ID');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    final nowUtc = _formatDateTimeToUtc(DateTime.now());

    for (final item in items) {
      try {
        final parts = item.time.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

        final start = DateTime.parse('${dateStr}T${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00');
        final end = start.add(const Duration(minutes: 30));

        final dtStart = _formatDateTimeToUtc(start);
        final dtEnd = _formatDateTimeToUtc(end);
        final uid = 'retiva-${item.id}-${start.millisecondsSinceEpoch}@retiva.health';

        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:$uid');
        buffer.writeln('DTSTAMP:$nowUtc');
        buffer.writeln('DTSTART:$dtStart');
        buffer.writeln('DTEND:$dtEnd');
        buffer.writeln('SUMMARY:Retiva: ${item.title}');
        buffer.writeln('DESCRIPTION:${item.subtitle}\\n${item.instructions ?? ''}');
        buffer.writeln('STATUS:CONFIRMED');
        buffer.writeln('BEGIN:VALARM');
        buffer.writeln('TRIGGER:-PT15M');
        buffer.writeln('ACTION:DISPLAY');
        buffer.writeln('DESCRIPTION:Pengingat Retiva: ${item.title}');
        buffer.writeln('END:VALARM');
        buffer.writeln('END:VEVENT');
      } catch (_) {}
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String _formatDateTimeToUtc(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '${y}${m}${d}T${h}${min}${s}Z';
  }
}
