import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class CalendarHelper {
  static final DeviceCalendarPlugin _deviceCalendarPlugin =
      DeviceCalendarPlugin();

  static bool _tzInitialized = false;

  static Future<void> _initTimeZone() async {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  static Future<void> addOrderEvent({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    await _initTimeZone();

    // Ask for permission
    var permissionStatus = await Permission.calendar.request();
    if (!permissionStatus.isGranted) return;

    // Get available calendars
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    final calendar = calendarsResult.data?.firstWhere(
      (c) => c.isDefault ?? false,
      orElse: () => calendarsResult.data!.first,
    );

    if (calendar == null) return;

    // Convert DateTime to timezone-aware TZDateTime
    final location = tz.local;
    final startTime = tz.TZDateTime.from(date, location);
    final endTime = tz.TZDateTime.from(
      date.add(const Duration(hours: 1)),
      location,
    );

    // Create event
    final event = Event(
      calendar.id,
      title: title,
      description: description,
      start: startTime,
      end: endTime,
      reminders: [Reminder(minutes: 60 * 24)], // 1 day before
    );

    await _deviceCalendarPlugin.createOrUpdateEvent(event);
  }
}
